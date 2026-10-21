# Data Management
Source data
The original supply chain dataset will be downloaded from its documented source. Its license, attribution requirements, file format, and column definitions must be reviewed before use.
Directory conventions
- raw/: Original source files. Do not modify these files.
- processed/: Locally generated cleaned or transformed files.
- sample_data/: Small, permitted examples used for testing or demonstration.
Data handling rules
1. Keep the original dataset unchanged.
2. Perform transformations through documented SQL scripts.
3. Do not upload the full dataset unless its license and size permit redistribution.
4. Do not include passwords, private information, or credentials.
5. Record cleaning decisions and any exclusions.
6. Clearly distinguish real source data from synthetic extensions.
Data lineage
Document each source file, its origin, its purpose, and the SQL process that transforms it into the final analytical tables.