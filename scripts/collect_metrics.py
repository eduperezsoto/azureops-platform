import glob
import pandas as pd

def collect():
    files = glob.glob("artifacts/*.json")
    rows = []
    for f in files:
        try:
            df = pd.read_json(f)
            rows.append(df)
        except ValueError:
            # Ignorar archivos no JSON o corruptos
            continue

    if rows:
        combined = pd.concat(rows, ignore_index=True)
        combined.to_csv("artifacts/metrics.csv", index=False)
        print("✅ Métricas consolidadas en artifacts/metrics.csv")
    else:
        print("⚠️ No se encontraron archivos JSON de métricas en artifacts/")

if __name__ == "__main__":
    collect()
