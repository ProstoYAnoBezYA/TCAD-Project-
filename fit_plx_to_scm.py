#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Аппроксимация одномерных профилей легирования из .plx файлов
суммой гауссиан и запись в формат .scm для Sentaurus SDE.

Координаты для бора вычисляются как смещение пика от поверхности
окна (Pocket_Window) вглубь подложки. Для фосфора используется
PeakPos=0 (пик прямо на поверхности окна истока/стока).

ValueAtDepth для обоих профилей задаётся физическим уровнем подложки
через аргументы --bg-p и --bg-b.
"""
import sys, os, argparse, math
import numpy as np
from scipy.optimize import least_squares
from scipy.signal import find_peaks


# Физические фоновые концентрации (уровень подложки) по умолчанию
#BG_P_SUBSTRATE = 1.7e15
#BG_B_SUBSTRATE = 1.0e15
BG_P_SUBSTRATE = 1.0e10
BG_B_SUBSTRATE = 1.0e10

def read_plx(path):
    zs, vs = [], []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('"'):
                continue
            parts = line.split()
            if len(parts) != 2:
                continue
            try:
                z = float(parts[0]); v = float(parts[1])
            except ValueError:
                continue
            zs.append(z); vs.append(v)
    return np.array(zs), np.array(vs)


def find_seed_peaks_smart(z, v, n_gauss):
    """Поиск стартовых позиций гауссиан через scipy.find_peaks."""
    if n_gauss == 1:
        return [float(z[int(np.argmax(v))])]

    try:
        peaks, props = find_peaks(v, prominence=v.max() * 0.05)
        peak_positions = sorted([float(z[p]) for p in peaks])
    except Exception:
        peak_positions = []

    if len(peak_positions) >= n_gauss:
        prominences = props.get('prominences', np.zeros(len(peaks)))
        top_idx = np.argsort(prominences)[::-1][:n_gauss]
        return sorted([float(z[peaks[i]]) for i in top_idx])

    seeds = list(peak_positions)
    needed = n_gauss - len(seeds)
    if len(seeds) >= 2:
        for i in range(len(peak_positions) - 1):
            if needed <= 0:
                break
            mid = (peak_positions[i] + peak_positions[i+1]) / 2.0
            seeds.append(mid)
            needed -= 1

    while needed > 0:
        best_z = None
        best_dist = 0.0
        for i in range(len(z)):
            dist_to_existing = min(abs(z[i] - s) for s in seeds) if seeds else (z.max() - z.min())
            if dist_to_existing > best_dist and v[i] > v.max() * 0.1:
                best_dist = dist_to_existing
                best_z = float(z[i])
        if best_z is None:
            best_z = (z.min() + z.max()) / 2.0
        seeds.append(best_z)
        needed -= 1

    return sorted(seeds)


def estimate_sigma_at_peak(z, v, z_peak):
    """Оценка sigma через полуширину на полувысоте."""
    idx_peak = int(np.argmin(np.abs(z - z_peak)))
    v_peak = v[idx_peak]
    half = v_peak / 2.0

    idx_right = idx_peak
    while idx_right < len(z) - 1 and v[idx_right] > half:
        idx_right += 1
    idx_left = idx_peak
    while idx_left > 0 and v[idx_left] > half:
        idx_left -= 1

    fwhm = abs(z[idx_right] - z[idx_left])
    sigma = fwhm / (2.0 * math.sqrt(math.log(2.0)))
    z_range = z.max() - z.min()
    sigma = max(min(sigma, z_range * 0.5), z_range * 0.01)
    return float(sigma)


def fit_sum_gaussians(z, v, n_gauss, bg, seed_peaks=None):
    def unpack(p):
        return [(p[3*k], p[3*k+1], p[3*k+2]) for k in range(n_gauss)]

    def model(p, zz):
        y = np.full_like(zz, bg, dtype=float)
        for z0, A, s in unpack(p):
            y = y + A * np.exp(-((zz - z0)/s)**2)
        return y

    def residuals(p):
        y = np.maximum(model(p, z), 1.0)
        return np.log(y) - np.log(np.maximum(v, 1.0))

    if seed_peaks is None:
        seed_peaks = find_seed_peaks_smart(z, v, n_gauss)

    v_max = float(v.max())
    z_range = float(z.max() - z.min())

    p0 = []
    for zp in seed_peaks:
        idx = int(np.argmin(np.abs(z - zp)))
        sigma_init = estimate_sigma_at_peak(z, v, zp)
        A_init = float(max(v[idx], v_max * 0.1))
        p0 += [float(zp), A_init, sigma_init]

    lo, hi = [], []
    for _ in range(n_gauss):
        lo += [float(z.min()), 1e14, z_range * 0.005]
        hi += [float(z.max()), v_max * 3.0, z_range * 0.7]

    res = least_squares(residuals, p0, bounds=(lo, hi), max_nfev=20000)
    params = unpack(res.x)
    pred = model(res.x, z)
    log_rmse = float(np.sqrt(np.mean(
        (np.log(np.maximum(pred, 1.0)) - np.log(np.maximum(v, 1.0)))**2
    )))
    return params, log_rmse


def gauss_to_sentaurus(peak_pos, A, sigma, value_at_depth):
    """Перевод параметров гауссианы в формат Sentaurus.
    peak_pos - уже в нужной системе координат (смещение от окна)."""
    eps = max(value_at_depth, 1.0)
    A_safe = max(A, eps * 1.001)
    depth = sigma * math.sqrt(math.log(A_safe / eps))
    return dict(peak_pos=peak_pos, peak_val=A, value_at_depth=eps,
                depth=depth, sigma=sigma)


def emit_scm(out_path, p_params, b_params,
             pocket_window, source_window, drain_window,
             gauss_factor=0.8,
             bg_p_substrate=BG_P_SUBSTRATE,
             bg_b_substrate=BG_B_SUBSTRATE):
    """Запись .scm файла.

    Координаты PeakPos уже пересчитаны в систему "смещение от окна"
    в вызывающем коде. Для фосфора это всегда 0 (пик на поверхности),
    для бора - расстояние от поверхности окна до пика вглубь."""
    lines = []
    P = lines.append

    # Фосфор: PeakPos уже = 0 для всех гауссиан
    for k, (peak_pos, A, sigma) in enumerate(p_params, start=1):
        d = gauss_to_sentaurus(peak_pos, A, sigma, bg_p_substrate)
        name = f"P{k}_Definition"
        P(f'(sdedr:define-gaussian-profile "{name}" "PhosphorusActiveConcentration"')
        P(f'   "PeakPos"      {d["peak_pos"]:.6f}')
        P(f'   "PeakVal"      {d["peak_val"]:.6e}')
        P(f'   "ValueAtDepth" {d["value_at_depth"]:.6e}')
        P(f'   "Depth"        {d["depth"]:.6f}')
        P(f'   "Gauss" "Factor" {gauss_factor})')
    for k in range(1, len(p_params)+1):
        P(f'(sdedr:define-analytical-profile-placement '
          f'"P{k}_Src_Place" "P{k}_Definition" "{source_window}" '
          f'"Both" "NoReplace" "Eval")')
        P(f'(sdedr:define-analytical-profile-placement '
          f'"P{k}_Drn_Place" "P{k}_Definition" "{drain_window}" '
          f'"Both" "NoReplace" "Eval")')
    P("")

    # Бор: PeakPos = смещение пика от поверхности окна вглубь (положительное)
    for k, (peak_pos, A, sigma) in enumerate(b_params, start=1):
        d = gauss_to_sentaurus(peak_pos, A, sigma, bg_b_substrate)
        name = f"B{k}_Definition"
        P(f'(sdedr:define-gaussian-profile "{name}" "BoronActiveConcentration"')
        P(f'   "PeakPos"      {d["peak_pos"]:.6f}')
        P(f'   "PeakVal"      {d["peak_val"]:.6e}')
        P(f'   "ValueAtDepth" {d["value_at_depth"]:.6e}')
        P(f'   "Depth"        {d["depth"]:.6f}')
        P(f'   "Gauss" "Factor" {gauss_factor})')
    for k in range(1, len(b_params)+1):
        P(f'(sdedr:define-analytical-profile-placement '
          f'"B{k}_Pocket_Place" "B{k}_Definition" "{pocket_window}" '
          f'"Both" "NoReplace" "Eval")')
    P("")

    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("p_plx")
    ap.add_argument("b_plx")
    ap.add_argument("out_scm")
    ap.add_argument("--np", type=int, default=1, dest="n_p")
    ap.add_argument("--nb", type=int, default=2, dest="n_b")
    ap.add_argument("--pocket-window", default="Pocket_Window")
    ap.add_argument("--source-window", default="Source_Window")
    ap.add_argument("--drain-window",  default="Drain_Window")
    ap.add_argument("--gauss-factor", type=float, default=0.8)
    ap.add_argument("--bg-p", type=float, default=BG_P_SUBSTRATE)
    ap.add_argument("--bg-b", type=float, default=BG_B_SUBSTRATE)
    ap.add_argument("--z-flip", action="store_true",
                    help="(не используется, оставлен для совместимости)")
    ap.add_argument("--z-plx-surface", type=float, default=None,
                    help="(не используется, оставлен для совместимости)")
    ap.add_argument("--z-sde-surface", type=float, default=None,
                    help="(не используется, оставлен для совместимости)")
    ap.add_argument("--report", default=None)
    args = ap.parse_args()

    zP, vP = read_plx(args.p_plx)
    zB, vB = read_plx(args.b_plx)

    # Фит в логарифмическом масштабе с фиксированным физическим фоном
    p_params, p_rmse = fit_sum_gaussians(zP, vP, args.n_p, args.bg_p)
    b_params, b_rmse = fit_sum_gaussians(zB, vB, args.n_b, args.bg_b)

    # Поверхность в .plx - первая точка после очистки
    z_plx_surface = float(zP[0])

    # Для фосфора PeakPos = 0 (пик прямо на поверхности окна S/D)
    p_params_sde = [(0.0, A, sigma) for (_, A, sigma) in p_params]

    # Для бора PeakPos = смещение пика от поверхности вглубь (положительное)
    b_params_sde = [(abs(z0 - z_plx_surface), A, sigma)
                    for (z0, A, sigma) in b_params]

    emit_scm(args.out_scm, p_params_sde, b_params_sde,
             pocket_window=args.pocket_window,
             source_window=args.source_window,
             drain_window=args.drain_window,
             gauss_factor=args.gauss_factor,
             bg_p_substrate=args.bg_p,
             bg_b_substrate=args.bg_b)

    report_lines = []
    R = report_lines.append
    R(f"# Phosphorus: bg={args.bg_p:.3e}, n_gauss={args.n_p}, log-RMSE={p_rmse:.4f}")
    for k, ((z0, A, s), (pp, _, _)) in enumerate(zip(p_params, p_params_sde), start=1):
        R(f"#   P{k}: z_plx={z0:.5f} -> PeakPos={pp:.5f}  A={A:.4e}  sigma={s:.5f}")
    R(f"# Boron: bg={args.bg_b:.3e}, n_gauss={args.n_b}, log-RMSE={b_rmse:.4f}")
    for k, ((z0, A, s), (pp, _, _)) in enumerate(zip(b_params, b_params_sde), start=1):
        R(f"#   B{k}: z_plx={z0:.5f} -> PeakPos={pp:.5f}  A={A:.4e}  sigma={s:.5f}")
    report = "\n".join(report_lines)
    print(report)
    if args.report:
        with open(args.report, "w") as f:
            f.write(report + "\n")


if __name__ == "__main__":
    main()
