"""
Groundwater Flow Analysis Script
Calculates total flow (converted to flux) for each CSV file for the year 2021
"""

import pandas as pd
import yaml
from pathlib import Path
from datetime import datetime
import sys


def load_config(config_path="config.yaml"):
    """Load configuration from YAML file"""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def parse_date(date_str):
    """Parse date string in multiple formats"""
    # Try format: MM/DD/YYYY
    try:
        return pd.to_datetime(date_str, format='%m/%d/%Y')
    except:
        pass

    # Try format: MM/DD/YYYY HH:MM:SS
    try:
        return pd.to_datetime(date_str, format='%m/%d/%Y %H:%M:%S')
    except:
        pass

    # Let pandas infer the format
    try:
        return pd.to_datetime(date_str)
    except:
        return None


def interpolate_to_daily(df, flow_column):
    """
    Interpolate data to daily timestep

    Args:
        df: DataFrame with Date column and flow data
        flow_column: Name of the flow column to interpolate

    Returns:
        DataFrame: Interpolated data on daily timestep
    """
    # Remove any rows with NaT dates
    df = df.dropna(subset=['Date'])

    # Set Date as index
    df = df.set_index('Date')

    # Sort by date
    df = df.sort_index()

    # Create daily date range from min to max date
    daily_range = pd.date_range(start=df.index.min(), end=df.index.max(), freq='D')

    # Reindex to daily frequency and interpolate
    df_daily = df.reindex(daily_range)

    # Interpolate the flow column (and other numeric columns)
    df_daily[flow_column] = df_daily[flow_column].interpolate(method='linear')

    # Reset index to make Date a column again
    df_daily = df_daily.reset_index()
    df_daily = df_daily.rename(columns={'index': 'Date'})

    return df_daily


def calculate_flow_for_file(file_path, flow_column, year=2021):
    """
    Calculate total flow for a specific year in a CSV file
    Flow is converted to flux by multiplying by 86400 (seconds per day)
    Data is first interpolated to daily timestep to ensure consistency

    Args:
        file_path: Path to CSV file
        flow_column: Name of the flow column
        year: Year to filter data (default 2021)

    Returns:
        tuple: (total_flux, row_count, error_message)
    """
    try:
        # Read CSV file
        df = pd.read_csv(file_path)

        # Check if flow column exists
        if flow_column not in df.columns:
            return None, 0, f"Column '{flow_column}' not found"

        # Parse dates
        df['Date'] = df['Date'].apply(parse_date)

        # Interpolate to daily timestep
        df_daily = interpolate_to_daily(df, flow_column)

        # Filter for the specified year
        df_year = df_daily[df_daily['Date'].dt.year == year].copy()

        if len(df_year) == 0:
            return 0.0, 0, f"No data found for year {year}"

        # Convert flow to flux (multiply by 86400 seconds/day)
        df_year['Flux'] = df_year[flow_column] * 86400

        # Calculate total flux
        total_flux = df_year['Flux'].sum()
        row_count = len(df_year)

        return total_flux, row_count, None

    except Exception as e:
        return None, 0, str(e)


def process_directory(directory_path, flow_column, year=2021):
    """
    Process all CSV files in a directory

    Args:
        directory_path: Path to directory containing CSV files
        flow_column: Name of the flow column
        year: Year to filter data

    Returns:
        list: List of dictionaries with results
    """
    results = []
    dir_path = Path(directory_path)

    if not dir_path.exists():
        print(f"Warning: Directory does not exist: {directory_path}")
        return results

    # Get all CSV files
    csv_files = sorted(dir_path.glob("*.csv"))

    for csv_file in csv_files:
        total_flux, row_count, error = calculate_flow_for_file(
            csv_file, flow_column, year
        )

        results.append({
            'Directory': dir_path.name,
            'Filename': csv_file.name,
            'Total_Flux_2020': total_flux if total_flux is not None else 0.0,
            'Row_Count': row_count,
            'Error': error if error else ''
        })

    return results


def main():
    """Main function to process all directories and generate report"""
    # Load configuration
    try:
        config = load_config()
    except FileNotFoundError:
        print("Error: config.yaml not found")
        sys.exit(1)

    flow_column = config['csv_settings']['flow_column']
    year = 2020

    all_results = []

    # Process each directory
    directories = config['directories']
    for dir_key, dir_path in directories.items():
        print(f"\nProcessing {dir_key}: {dir_path}")
        results = process_directory(dir_path, flow_column, year)
        all_results.extend(results)
        print(f"  Found {len(results)} files")

    # Create DataFrame with results
    df_results = pd.DataFrame(all_results)

    # Display results
    print("\n" + "="*100)
    print(f"GROUNDWATER FLOW ANALYSIS - Year {year}")
    print(f"Data interpolated to daily timestep before analysis")
    print(f"Flow converted to flux by multiplying by 86400 (seconds/day)")
    print("="*100 + "\n")

    if len(df_results) > 0:
        # Format the display
        pd.set_option('display.max_rows', None)
        pd.set_option('display.max_columns', None)
        pd.set_option('display.width', None)
        pd.set_option('display.float_format', '{:.6f}'.format)

        # Display table
        print(df_results.to_string(index=False))

        # Summary statistics by directory
        print("\n" + "="*100)
        print("SUMMARY BY DIRECTORY")
        print("="*100 + "\n")

        summary = df_results.groupby('Directory').agg({
            'Total_Flux_2020': 'sum',
            'Filename': 'count'
        }).rename(columns={'Filename': 'File_Count'})

        print(summary.to_string())

        # Overall total
        print("\n" + "="*100)
        print(f"OVERALL TOTAL FLUX (2020): {df_results['Total_Flux_2020'].sum():.6f}")
        print("="*100)

        # Save to CSV
        output_file = config['output'].get('output_file', 'flow_summary_2020.csv')
        df_results.to_csv(output_file, index=False)
        print(f"\nResults saved to: {output_file}")

    else:
        print("No results to display")


if __name__ == "__main__":
    main()
