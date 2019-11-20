# Improvements to C/C++ analysis

The following changes in version 1.24 affect C/C++ analysis in all applications.

## General improvements

## New queries

| **Query**                   | **Tags**  | **Purpose**                                                        |
|-----------------------------|-----------|--------------------------------------------------------------------|

## Changes to existing queries

| **Query**                  | **Expected impact**    | **Change**                                                       |
|----------------------------|------------------------|------------------------------------------------------------------|
| No space for zero terminator (`cpp/no-space-for-terminator`) | Fewer false positive results | This query has been modified to be more conservative when identifying which pointers point to null-terminated strings.  This approach produces fewer, more accurate results. |

## Changes to libraries

* `FormattingFunction`s are now included in the `ArrayFunction` model.  Only fixed parameters (not varargs) are included in the model.
