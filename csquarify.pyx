# -*- coding: utf-8 -*-
"""
Created on Thu Mar  3 14:24:47 2022

Squarified Treemap Layout
Implements algorith from Bruls, Huizing, van Wijk, "Squarified Treemaps"

@author: Emmett
"""
import cython

cdef struct Rect:
    float x
    float y
    float dx
    float dy


cdef void pad_rectangle(rect: Rect):
    if rect[ "dx" ] > 2:
        rect[ "x" ] += 1
        rect[ "dx" ] -= 2
    if rect[ "dy" ] > 2:
        rect[ "y" ] += 1
        rect[ "dy" ] -= 2


cdef list[Rect] layoutrow(sizes: list[cython.float], 
                          x: cython.float, y: cython.float, 
                          dx: cython.float, dy: cython.float):
    # generate rects for each size in sizes
    # dx >= dy
    # they will fill up height dy, and width will be determined by their area
    # sizes should be pre-normalized wrt dx * dy (i.e., they should be same units)
    covered_area: cython.float = sum(sizes)
    width: cython.float = covered_area / dy
    rects: List[Rect] = [Rect(x, y + size/width, width, size/width) 
                         for size in sizes]
    
    return rects


cdef list[Rect] layoutcol(sizes: list[cython.float],
                          x: cython.float, y: cython.float,
                          dx: cython.float,dy: cython.float):
    # generate rects for each size in sizes
    # dx < dy
    # they will fill up width dx, and height will be determined by their area
    # sizes should be pre-normalized wrt dx * dy (i.e., they should be same units)
    covered_area: cython.float = sum(sizes)
    height: cython.float = covered_area / dx
    rects: list[cython.float] = [ Rect(x + size/ height, y, size / height, height)
    for size in sizes]
    return rects


cdef list[Rect] layout(sizes: list[cython.float],
                       x: cython.float, y: cython.float,
                       dx: cython.float,dy: cython.float):
    return (
        layoutrow(sizes, x, y, dx, dy) if dx >= dy else layoutcol(sizes, x, y, dx, dy)
    )


cdef leftoverrow(sizes: list[cython.float],
                          x: cython.float, y: cython.float,
                          dx: cython.float,dy: cython.float):
    # compute remaining area when dx >= dy
    covered_area: cython.float = sum(sizes)
    width: cython.float = covered_area / dy
    leftover_x: cython.float = x + width
    leftover_y: cython.float = y
    leftover_dx: cython.float = dx - width
    leftover_dy: cython.float = dy
    return (leftover_x, leftover_y, leftover_dx, leftover_dy)


cdef leftovercol(sizes: list[cython.float],
                          x: cython.float, y: cython.float,
                          dx: cython.float,dy: cython.float):
    # compute remaining area when dx >= dy
    covered_area: cython.float = sum(sizes)
    height: cython.float = covered_area / dx
    leftover_x: cython.float = x
    leftover_y: cython.float = y + height
    leftover_dx: cython.float = dx
    leftover_dy: cython.float = dy - height
    return (leftover_x, leftover_y, leftover_dx, leftover_dy)


cdef leftover(sizes: list[cython.float],
                       x: cython.float, y: cython.float,
                       dx: cython.float,dy: cython.float):
    return (
        leftoverrow(sizes, x, y, dx, dy)
        if dx >= dy
        else leftovercol(sizes, x, y, dx, dy)
    )


cdef float worst_ratio(sizes: list[cython.float],
                       x: cython.float, y: cython.float,
                       dx: cython.float,dy: cython.float):
    return max(
        [
            max(rect["dx"] / rect["dy"], rect["dy"] / rect["dx"])
            for rect in layout(sizes, x, y, dx, dy) if rect["dx"] != 0 and rect["dy"] != 0 
        ]
    )


# PUBLIC API


cpdef list[Rect] squarify(sizes: list[cython.float],
                       x: cython.float, y: cython.float,
                       dx: cython.float,dy: cython.float):
    """Compute treemap rectangles.

    Given a set of values, computes a treemap layout in the specified geometry
    using an algorithm based on Bruls, Huizing, van Wijk, "Squarified Treemaps".
    See README for example usage.

    Parameters
    ----------
    sizes : list-like of numeric values
        The set of values to compute a treemap for. `sizes` must be positive
        values sorted in descending order and they should be normalized to the
        total area (i.e., `dx * dy == sum(sizes)`)
    x, y : numeric
        The coordinates of the "origin".
    dx, dy : numeric
        The full width (`dx`) and height (`dy`) of the treemap.

    Returns
    -------
    list[dict]
        Each dict in the returned list represents a single rectangle in the
        treemap. The order corresponds to the input order.
    """
    sizes = list(map(float, sizes))

    if len(sizes) == 0:
        return []

    if len(sizes) == 1:
        return layout(sizes, x, y, dx, dy)

    # figure out where 'split' should be
    i = 1
    while i < len(sizes) and worst_ratio(sizes[:i], x, y, dx, dy) >= worst_ratio(
        sizes[: (i + 1)], x, y, dx, dy
    ):
        i += 1
    current = sizes[:i]
    remaining = sizes[i:]

    leftover_x, leftover_y, leftover_dx, leftover_dy = leftover(current, x, y, dx, dy)
    return layout(current, x, y, dx, dy) + squarify(
        remaining, leftover_x, leftover_y, leftover_dx, leftover_dy
    )


# cdef padded_squarify(sizes, x, y, dx, dy):
#     """Compute padded treemap rectangles.

#     See `squarify` docstring for details. The only difference is that the
#     returned rectangles have been "padded" to allow for a visible border.
#     """
#     rects = squarify(sizes, x, y, dx, dy)
#     for rect in rects:
#         pad_rectangle(rect)
#     return rects


# cdef normalize_sizes(sizes, dx, dy):
#     """Normalize list of values.

#     Normalizes a list of numeric values so that `sum(sizes) == dx * dy`.

#     Parameters
#     ----------
#     sizes : list-like of numeric values
#         Input list of numeric values to normalize.
#     dx, dy : numeric
#         The dimensions of the full rectangle to normalize total values to.

#     Returns
#     -------
#     list[numeric]
#         The normalized values.
#     """
#     total_size = sum(sizes)
#     total_area = dx * dy
#     sizes = map(float, sizes)
#     sizes = map(lambda size: size * total_area / total_size, sizes)
#     return list(sizes)


# cdef plot(
#     sizes,
#     norm_x=100,
#     norm_y=100,
#     color=None,
#     label=None,
#     value=None,
#     ax=None,
#     pad=False,
#     bar_kwargs=None,
#     text_kwargs=None,
#     **kwargs
# ):
#     """Plotting with Matplotlib.

#     Parameters
#     ----------
#     sizes
#         input for squarify
#     norm_x, norm_y
#         x and y values for normalization
#     color
#         color string or list-like (see Matplotlib documentation for details)
#     label
#         list-like used as label text
#     value
#         list-like used as value text (in most cases identical with sizes argument)
#     ax
#         Matplotlib Axes instance
#     pad
#         draw rectangles with a small gap between them
#     bar_kwargs : dict
#         keyword arguments passed to matplotlib.Axes.bar
#     text_kwargs : dict
#         keyword arguments passed to matplotlib.Axes.text
#     **kwargs
#         Any additional kwargs are merged into `bar_kwargs`. Explicitly provided
#         kwargs here will take precedence.

#     Returns
#     -------
#     matplotlib.axes.Axes
#         Matplotlib Axes
#     """

#     import matplotlib.pyplot as plt

#     if ax is None:
#         ax = plt.gca()

#     if color is None:
#         import matplotlib.cm
#         import random

#         cmap = matplotlib.cm.get_cmap()
#         color = [cmap(random.random()) for _ in range(len(sizes))]

#     if bar_kwargs is None:
#         bar_kwargs = {}
#     if text_kwargs is None:
#         text_kwargs = {}
#     if len(kwargs) > 0:
#         bar_kwargs.update(kwargs)

#     normed = normalize_sizes(sizes, norm_x, norm_y)

#     if pad:
#         rects = padded_squarify(normed, 0, 0, norm_x, norm_y)
#     else:
#         rects = squarify(normed, 0, 0, norm_x, norm_y)

#     x = [rect["x"] for rect in rects]
#     y = [rect["y"] for rect in rects]
#     dx = [rect["dx"] for rect in rects]
#     dy = [rect["dy"] for rect in rects]

#     ax.bar(
#         x, dy, width=dx, bottom=y, color=color, label=label, align="edge", **bar_kwargs
#     )

#     if value is not None:
#         va = "center" if label is None else "top"

#         for v, r in zip(value, rects):
#             x, y, dx, dy = r["x"], r["y"], r["dx"], r["dy"]
#             ax.text(x + dx / 2, y + dy / 2, v, va=va, ha="center", **text_kwargs)

#     if label is not None:
#         va = "center" if value is None else "bottom"
#         for l, r in zip(label, rects):
#             x, y, dx, dy = r["x"], r["y"], r["dx"], r["dy"]
#             ax.text(x + dx / 2, y + dy / 2, l, va=va, ha="center", **text_kwargs)

#     ax.set_xlim(0, norm_x)
#     ax.set_ylim(0, norm_y)

#     return ax
