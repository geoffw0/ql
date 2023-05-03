.. _codeql-library-for-swift:

CodeQL library for Swift
========================

When analyzing Swift code, you can use the large collection of classes in the CodeQL library for Swift.

About the CodeQL library for Swift
----------------------------------

There is an extensive library for analyzing CodeQL databases extracted from Swift projects. The classes in this library present the data from a database in an object-oriented form and provide abstractions and predicates to help you with common analysis tasks. 
The library is implemented as a set of QL modules, that is, files with the extension ``.qll``. The module ``swift.qll`` imports all the core Swift library modules, so you can include the complete library by beginning your query with:

.. code-block:: ql

   import swift

The rest of this topic summarizes the available CodeQL classes and corresponding Swift constructs.

Commonly-used library classes
------------------------------

The most commonly used standard library classes are listed below.  The listing is broken down by functionality. Each library class is annotated with a Swift construct it corresponds to.

Declaration classes
~~~~~~~~~~~~~~~~~~~

This table lists Declaration_ classes representing Swift declarations.

TODO: are Declarations, Statements, Expressions, Types the right top level groupings for Swift?
Are there any other things we should cover?
TODO

Statement classes
~~~~~~~~~~~~~~~~~

This table lists subclasses of Stmt_ representing Swift statements.

TODO


Expression classes
~~~~~~~~~~~~~~~~~~

This table lists subclasses of Expr_ representing Swift expressions.

TODO

Type classes
~~~~~~~~~~~~

This table lists subclasses of Type_ representing Swift types.

TODO

Further reading
---------------

.. include:: ../reusables/swift-further-reading.rst
.. include:: ../reusables/codeql-ref-tools-further-reading.rst

.. Links used in tables. For information about using these links, see
   https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html#hyperlinks.

TODO
