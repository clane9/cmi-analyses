import argparse
import logging
import os
import pprint
import time
from pathlib import Path
from itertools import product
from typing import Tuple
from glob import glob

from dask import distributed
from dask import dataframe as dd
import duckdb
import numpy as np
import pandas as pd
from pyarrow import dataset as pads
import vaex

# vaex.settings.main.memory_tracker.type = "limit"
vaex.settings.main.memory_tracker.max = "16GB"


logging.basicConfig(
    format="%(asctime)s %(levelname)-8s %(message)s",
    level=logging.INFO,
    datefmt="%Y-%m-%d %H:%M:%S",
)

NROWS = 10 ** np.arange(3, 6)
NELEMS = 10 ** np.arange(1, 5)


def main(args):
    logging.info("Args:\n%s", pprint.pformat(args.__dict__))

    if args.method == "duckdb":
        testfun = run_test_duckdb
    elif args.method == "duckdb_v2":
        testfun = run_test_duckdb_v2
    elif args.method == "pandas":
        testfun = run_test_pandas
    elif args.method == "dask":
        testfun = run_test_dask
    elif args.method == "vaex":
        testfun = run_test_vaex
    else:
        raise ValueError(f"unrecognized method {args.method}")

    results = []

    for trial in range(args.trials):
        logging.info("trial: %d/%d", trial, args.trials)
        for nrow, nelem in product(NROWS, NELEMS):
            _, rt, val = testfun(nrow, nelem)
            results.append([args.method, trial, nrow, nelem, rt, val])

    results = pd.DataFrame(
        results, columns=["method", "trial", "nrow", "nelem", "rt", "val"]
    )

    agg_results = results.groupby(["method", "nrow", "nelem"]).agg({"rt": "median"})
    logging.info("Results:\n%s", agg_results)

    if args.outdir is not None:
        os.makedirs(args.outdir, exist_ok=True)
        results.to_csv(Path(args.outdir) / f"{args.method}.csv", index=False)


def run_test_duckdb(
    nrows: int,
    nelem: int,
    root: str = "data",
    expected_n: int = 200,
) -> Tuple[pd.DataFrame, float, float]:

    tic = time.monotonic()
    datadir = Path(root)  / f"nrows-{nrows}_nelem-{nelem}"
    attrib = duckdb.from_parquet(str(datadir / "attrib/attrib.parquet"))
    arrays = duckdb.from_parquet(str(datadir / "arrays/arrays-*.parquet"))

    threshold = expected_n / len(attrib)
    filtered = attrib.filter(f"attrib < {threshold:.6f}")
    filtered = filtered.set_alias("filtered")
    arrays = arrays.set_alias("arrays")

    joined = filtered.join(
        arrays,
        "filtered.__index_level_0__ = arrays.__index_level_0__",
    ).df()
    result = dummy_calculation(joined)
    rt = time.monotonic() - tic
    return joined, rt, result


def run_test_duckdb_v2(
    nrows: int,
    nelem: int,
    root: str = "data",
    expected_n: int = 200,
) -> Tuple[pd.DataFrame, float, float]:

    tic = time.monotonic()
    datadir = Path(root)  / f"nrows-{nrows}_nelem-{nelem}"
    # NOTE: somehow duckdb automatically finds these objects
    attrib = pads.dataset(str(datadir / "attrib"))
    arrays = pads.dataset(str(datadir / "arrays"))

    threshold = expected_n / nrows

    sql = f"""
with filtered as (
    select * from attrib where attrib.attrib < {threshold:.6f}
)
select
    filtered.__index_level_0__, arrays.__index_level_0__, filtered.attrib, arrays.array
from filtered
left join arrays
    on filtered.__index_level_0__ = arrays.__index_level_0__"""
    joined = CON.query(sql).df()
    result = dummy_calculation(joined)
    rt = time.monotonic() - tic
    return joined, rt, result


def run_test_pandas(
    nrows: int,
    nelem: int,
    root: str = "data",
    expected_n: int = 200,
) -> Tuple[pd.DataFrame, float, float]:

    tic = time.monotonic()
    datadir = Path(root)  / f"nrows-{nrows}_nelem-{nelem}"
    attrib = pd.read_parquet(str(datadir / "attrib/attrib.parquet"))

    threshold = expected_n / len(attrib)
    filtered = attrib.loc[attrib["attrib"] < round(threshold, 6)]

    joined = []
    array_paths = sorted(glob(str(datadir / "arrays/arrays-*.parquet")))
    for array_path in array_paths:
        arrays = pd.read_parquet(array_path)
        joined.append(filtered.join(arrays, how="inner"))
    joined = pd.concat(joined, ignore_index=True)
    result = dummy_calculation(joined)
    rt = time.monotonic() - tic
    return joined, rt, result


def run_test_dask(
    nrows: int,
    nelem: int,
    root: str = "data",
    expected_n: int = 200,
) -> Tuple[pd.DataFrame, float, float]:

    tic = time.monotonic()
    datadir = Path(root)  / f"nrows-{nrows}_nelem-{nelem}"
    attrib = dd.read_parquet(datadir / "attrib")
    arrays = dd.read_parquet(datadir / "arrays")

    threshold = expected_n / nrows
    filtered = attrib.query(f"attrib < {threshold:.6f}")
    joined = filtered.join(arrays).compute()
    result = dummy_calculation(joined)
    rt = time.monotonic() - tic

    del attrib, arrays, filtered
    return joined, rt, result


def run_test_vaex(
    nrows: int,
    nelem: int,
    root: str = "data",
    expected_n: int = 200,
) -> Tuple[pd.DataFrame, float, float]:

    tic = time.monotonic()
    datadir = Path(root)  / f"nrows-{nrows}_nelem-{nelem}"
    attrib = vaex.open(datadir / "attrib")
    arrays = vaex.open(datadir / "arrays")

    threshold = expected_n / nrows
    filtered = attrib[attrib.attrib < round(threshold, 6)]
    joined = filtered.join(arrays).to_pandas_df()
    result = dummy_calculation(joined)
    rt = time.monotonic() - tic

    attrib = arrays = filtered = None
    return joined, rt, result


def dummy_calculation(df: pd.DataFrame) -> float:
    array_values = df["array"].values
    array_values = np.concatenate(array_values)
    return np.mean(array_values)


if __name__ == "__main__":
    parser = argparse.ArgumentParser("query_benchmark")
    parser.add_argument("--method", "-m", metavar="NAME", type=str,
        choices=["duckdb", "duckdb_v2", "pandas", "dask", "vaex"],
        help="test method name"
    )
    parser.add_argument("--trials", "-t", metavar="NUM", type=int, default=1,
        help="number of trials to run"
    )
    parser.add_argument("--outdir", "-o", metavar="PATH", type=str, default=None,
        help="path to output directory"
    )
    args = parser.parse_args()

    CON = CLUSTER = CLIENT = None
    if args.method.startswith("duckdb"):
        CON = duckdb.connect()
        CON.query("SET memory_limit='16GB'; SET threads TO 8")
    elif args.method.startswith("dask"):
        CLUSTER = distributed.LocalCluster(
            n_workers=8,
            memory_limit="2GB",
            processes=True,
        )
        CLIENT = distributed.Client(CLUSTER)

    # NOTE: For dask I tried to shutdown the client/cluster manually using
    # combinations of `cluster.close()`, `client.close()`, `client.shutdown()`.
    # All raised errors related to this issue:
    # https://github.com/dask/distributed/issues/6087. So I gave up and it seems
    # dask is good enough to clean up after itself.
    # NOTE: dask with `processes=False` fails with this issue:
    # https://github.com/dask/dask/issues/8012
    main(args)
