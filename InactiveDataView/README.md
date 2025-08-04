# Inactive Disk View

This is a lightweight web application for visualizing disk usage and identifying inactive or large datasets across file systems.

## Features

- **Visualize Disk Usage**: View inactive or large data directories in an interactive table.
- **Powerful Filtering**:
  - **Inactive Period**: Filter files by time since last access.
  - **Count**: Filter directories with high file counts.
  - **Size (TiB)**: Filter by disk usage.
  - **Group/User Filtering**: Narrow down by owner or group.
- **OnDemand Integration**: Quickly access file paths via OnDemand's file browser or open a terminal directly.

## How to install

```
# cd InactiveDataView/
# npm ci
# (edit if needed) manifest.yml
```

The app expects a JSON file with an array of objects like:

```json
[
  {
    "dt": "1724303999",
    "path": "/path/to/data",
    "grp": "groupname",
    "usr": "username",
    "Period": "24m",
    "count": "12345",
    "size": "3.14"
  },
  ...
]
```

The path to the json file is defined by the variable `dataPath` in `app.js`.
The sample is `data/sample.json`.

## How to Use
### 1. Load Dataset

Select a dataset from the dropdown at the top. Data will automatically be loaded from a JSON file.

### 2. Apply Filters

Each of the following fields can be adjusted using range sliders with dual handles for lower and upper bounds:

- **Inactive Period**: Filters by time since last access.
- **Count**: Filters by number of files per entry.
- **Size (TiB)**: Filters by directory size.

You can also narrow the results by selecting a specific user or group.

### 3. Table Content

- **Date (UTC)**: Timestamp of the last recorded activity.
- **Path**: Links to the path in OnDemand. Includes file browser and terminal icons.
- **Group / User**: Ownership info.
- **Inactive Period / Count / Size**: Inactivity period, file count, and size in TiB.

