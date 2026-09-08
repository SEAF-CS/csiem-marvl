# 005_1.7_summarry_images

This runner generates summary images with:
- period-based windows (`1989_2000`, `2001_2012`, `2013_2024`, `2021_2025`)
- standardized variable folder names (`AMM`, `TP`, `TURBIDITY`, etc.)
## Expected output

- Base folder:
  - `G:\CSIEM\1.7.0\csiem-marvl\outputs\005_1.7_summarry_images`
- Period subfolders:
  - `1989_2000`
  - `2001_2012`
  - `2013_2024`
  - `2021_2025`

## Run from CMD

```bat
cd /d G:\CSIEM\1.7.0\csiem-marvl
if not exist logs mkdir logs
taskkill /IM matlab.exe /F
start "" /b cmd /c "matlab -nosplash -nodesktop -batch "maxNumCompThreads(1); run('configs/005_1.7_summarry_images/RUN_MARVL_WQ_SI.m')" > logs\marvl_run.log 2>&1"
```

## Watch the log live

```bat
powershell -NoProfile -Command "while ($true) { Get-Content 'G:\CSIEM\1.7.0\csiem-marvl\logs\marvl_run.log' -Tail 80 -ErrorAction SilentlyContinue; Start-Sleep 2; Clear-Host }"
```

