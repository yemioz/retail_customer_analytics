"""Clean monthly transaction CSV files before PostgreSQL ingestion."""

from pathlib import Path
import pandas as pd


INPUT_DIR = Path("data/raw/transactions")
OUTPUT_DIR = Path("data/processed/transactions_clean")


def clean_transaction_files(
    input_dir: Path = INPUT_DIR,
    output_dir: Path = OUTPUT_DIR,
) -> None:
    """Convert nullable ID columns and save cleaned monthly transaction files."""

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory not found: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    files_processed = 0

    for file_path in sorted(input_dir.glob("*.csv")):
        # Skip macOS metadata files and empty files.
        if file_path.name.startswith("._"):
            continue

        if file_path.stat().st_size == 0:
            continue

        df = pd.read_csv(file_path)

        required_columns = {"user_id", "voucher_id"}
        missing_columns = required_columns.difference(df.columns)

        if missing_columns:
            raise ValueError(
                f"{file_path.name} is missing required columns: "
                f"{sorted(missing_columns)}"
            )

        # Preserve missing values while storing valid IDs as integers.
        df["user_id"] = df["user_id"].astype("Int64")
        df["voucher_id"] = df["voucher_id"].astype("Int64")

        output_file = output_dir / file_path.name
        df.to_csv(output_file, index=False)

        files_processed += 1
        print(f"Cleaned {file_path.name}")

    print(f"Completed preprocessing {files_processed} transaction files.")


if __name__ == "__main__":
    clean_transaction_files()
