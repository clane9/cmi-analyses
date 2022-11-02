# CMI Analyses

A repository of MRI analysis code for the
[CMI](https://childmind.org/science/advancing-methods/computational-neuroimaging-lab/).


## Adding an analysis directory

```sh
git remote add <analysis> ssh://<user>@<server>:/path/to/remote/repo
git subtree add --prefix <analysis> <analysis> <commit>
```

## Index

- [rbc-distcorr](rbc-distcorr/): Comparing C-PAC vs fmriprep
  distortion correction processing for RBC.

