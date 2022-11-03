# Parquet join query

In this quick experiment we benchmark the performance of [DuckDB](https://duckdb.org/) on querying large vector data from a [parquet](https://parquet.apache.org/) database.

In [generate_datasets.ipynb](generate_datasets.ipynb), we construct synthetic datasets consisting of:

- An `attrib` table containing two columns: an integer `index` in `[0, nrows)` and a random float `attrib` in `[0, 1]`.
- An `arrays` table also containing a matching `index`, as well as an `array` column containing random NumPy arrays of shape `(nelem,)`.

In [query_analysis.ipynb](query_analysis.ipynb), we evaluate the performance of querying the `arrays` table using a filter generated from `attrib`

```python
# read parquet tables as "relations"
# this is lazy and does not read the full data into memory
attrib = duckdb.from_parquet("attrib.parquet")
arrays = duckdb.from_parquet("arrays-*.parquet")

# filter on attrib
threshold = 200 / len(attrib)
filtered = attrib.filter(f"attrib < {threshold:.6f}")

# join with arrays
# the returned df is a pandas DataFrame
filtered = filtered.set_alias("filtered")
arrays = arrays.set_alias("arrays")
df = filtered.join(arrays, "filtered.index = arrays.index").df()
```

More details and examples can be found [here](https://github.com/duckdb/duckdb/blob/master/examples/python/duckdb-python.py) and [here](https://duckdb.org/2021/06/25/querying-parquet.html).

Here are the results of our test

| nrow | nelem | runtime (s) |
|---|---|---|
| 1000 | 10 | 0.003757 |
| 1000 | 100 | 0.009874 |
| 1000 | 1000 | 0.140762 |
| 1000 | 10000 | 0.762913 |
| 10000 | 10 | 0.053829 |
| 10000 | 100 | 0.110057 |
| 10000 | 1000 | 0.269147 |
| 10000 | 10000 | 1.407382 |
| 100000 | 10 | 0.059533 |
| 100000 | 100 | 0.253589 |
| 100000 | 1000 | 1.003703 |
| 100000 | 10000 | 2.797853 |


In the largest case, DuckDB is able to query and process 200 rows of vector data from the 32GB `arrays` table in only 2.8s.
