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

We compare DuckDB's performance to a more "naive" approach using pandas that reads all the data and executes the joins in batches.

Here are the results of our test

|   nrow |   nelem |   runtime (DuckDB) |   runtime (pandas) |
|-------:|--------:|-------------------:|-------------------:|
|   1000 |      10 |         0.00729267 |         0.119576   |
|   1000 |     100 |         0.0136764  |         0.00939533 |
|   1000 |    1000 |         0.0761871  |         0.019083   |
|   1000 |   10000 |         0.593045   |         0.12254    |
|  10000 |      10 |         0.0097008  |         0.011616   |
|  10000 |     100 |         0.0230262  |         0.0214925  |
|  10000 |    1000 |         0.103769   |         0.110753   |
|  10000 |   10000 |         0.806461   |         1.04455    |
| 100000 |      10 |         0.0229186  |         0.0559437  |
| 100000 |     100 |         0.0502371  |         0.147699   |
| 100000 |    1000 |         0.248135   |         1.06513    |
| 100000 |   10000 |         2.99795    |        10.3386     |

Interestingly, DuckDB provides a clear performance benefit over the "naive" pandas approach in only the largest scale cases. In small cases where all the data fits easily in memory, I guess you're better off keeping things simple.

(Nb. Disregard the runtime for pandas in the first case. This is probably inflated by pandas importing [PyArrow](https://arrow.apache.org/docs/python/index.html).)
