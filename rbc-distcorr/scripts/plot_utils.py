from typing import Any, List, Optional, Union, Tuple
from glob import glob
from pathlib import Path

import numpy as np
import nibabel as nib
from nilearn.image import resample_to_img
from matplotlib import pyplot as plt
from matplotlib.colors import ListedColormap


def match_pattern(pattern: Union[Path, str]) -> str:
    if isinstance(pattern, Path):
        pattern = pattern.as_posix()
    return glob(pattern)[0]


def combine_rois(roi_images: List[nib.Nifti1Image]) -> nib.Nifti1Image:
    shape, affine = roi_images[0].shape, roi_images[0].affine
    atlas = np.zeros(shape, dtype=np.int16)

    for ii, img in enumerate(roi_images):
        assert (
            img.shape == shape and np.allclose(img.affine, affine)
        ), "all images must have the same shape and affine"

        atlas[img.get_fdata() > 0] = ii + 1

    atlas = nib.Nifti1Image(atlas, affine)
    return atlas


def apply_affine(coord: np.ndarray, affine: np.ndarray) -> np.ndarray:
    coord = np.asarray(coord).astype(affine.dtype)
    singleton = coord.ndim == 1
    if singleton:
        coord = coord.reshape(1, -1)
    assert coord.shape[1] == 3
    coord = np.concatenate([coord, np.ones((len(coord), 1))], axis=1)
    coord = coord @ affine.T
    coord = coord[:, :3]
    if singleton:
        coord = coord.flatten()
    return coord


def coord2vox(coord: np.ndarray, affine: np.ndarray) -> np.ndarray:
    ind = apply_affine(coord, np.linalg.inv(affine))
    ind = ind.astype(np.int32)
    return ind


def vox2coord(ind: np.ndarray, affine: np.ndarray) -> np.ndarray:
    coord = apply_affine(ind, affine)
    return coord


def get_slice(img: np.ndarray, idx: int, dim: int = 0, t: int = 0):
    assert img.ndim in {3, 4}, "expected 3D or 4D Nifti"
    slc = [idx if ii == dim else slice(None) for ii in range(3)]
    if img.ndim == 4:
        slc.append(t)
    slice_data = img[tuple(slc)]
    return slice_data


def letterbox(img: np.ndarray, value: float = 0.0):
    assert img.ndim >= 2, "expected img ndim >= 2"
    h, w = img.shape[:2]
    sz = max(w, h)
    padding = [max(sz - img.shape[ii], 0) if ii < 2 else 0 for ii in range(img.ndim)]
    padding = [(p // 2, p - p // 2) for p in padding]
    img = np.pad(img, padding, constant_values=value)
    return img


def plot_slice(
    img: nib.Nifti1Image,
    coord: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    dim: int = 0,
    square: bool = True,
    mask: bool = False,
    threshold: float = 0.0,
    **imshow_kwargs,
):
    ind = coord2vox(coord, img.affine)
    slice_data = get_slice(img.dataobj, ind[dim], dim=dim)
    if square:
        slice_data = letterbox(slice_data)
    if mask:
        slice_data = np.where(slice_data > threshold, slice_data, np.nan)
    imshow_kwargs.update(origin="lower")
    art = plt.imshow(slice_data.T, **imshow_kwargs)
    return art


def plot_array_slice(
    img: np.ndarray,
    ind: int = 45,
    dim: int = 0,
    square: bool = True,
    mask: bool = False,
    threshold: float = 0.0,
    **imshow_kwargs,
):
    slice_data = get_slice(img, ind, dim=dim)
    if square:
        slice_data = letterbox(slice_data)
    if mask:
        slice_data = np.where(slice_data > threshold, slice_data, np.nan)
    imshow_kwargs.update(origin="lower")
    art = plt.imshow(slice_data.T, **imshow_kwargs)
    return art


def plot_mask(
    mask: nib.Nifti1Image,
    coord: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    dim: int = 0,
    square: bool = True,
    threshold: float = 0.0,
    alpha: float = 0.7,
    color: Any = "blue",
    **imshow_kwargs,
):
    return plot_slice(
        mask,
        coord=coord,
        dim=dim,
        square=square,
        cmap=ListedColormap([color]),
        mask=True,
        threshold=threshold,
        alpha=0.7,
        vmin=0.0,
        **imshow_kwargs,
    )


def plot_masks(
    t1w: nib.Nifti1Image,
    masks: List[nib.Nifti1Image],
    colors: Optional[List[Any]] = None,
    coord: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    plot_width: int = 3.0,
    threshold: float = 0.0,
    fname: str = None,
):
    f, axs = plt.subplots(
        1, 3, figsize=(3 * plot_width, plot_width), sharey=True, sharex=True
    )

    if colors is None:
        colors = plt.get_cmap("gist_ncar")(np.linspace(0, 1, len(masks)))

    for dim in range(3):
        plt.sca(axs[dim])
        plot_slice(t1w, coord=coord, dim=dim, cmap="gray")
        for mask, color in zip(masks, colors):
            mask = resample_to_img(mask, t1w, interpolation="nearest") 
            plot_mask(
                mask,
                coord=coord,
                dim=dim,
                color=color,
                threshold=threshold,
            )
    plt.tight_layout()

    if fname is not None:
        f.savefig(fname, bbox_inches="tight")
    return f
