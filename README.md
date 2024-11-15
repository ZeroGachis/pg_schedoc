# schedoc

schedoc means schema documentation, it's a tool to build an automatic
documentation based on COMMENT on PostgresSQL objects. schedoc require
the extension
[(ddl_historization](https://pgxn.org/dist/ddl_historization/) to work

COMMENT are set on columns in a json format with predefined values like status.

```
COMMENT ON COLUMN foobar.id IS '{"status": "private"}'
```

Comment are parsed and store in a table to make information easy accessible

```
[local]:5437 rodo@jeanneau=# SELECT * FROM schedoc_column_comments ;
 databasename | tablename | columnname | status
--------------+-----------+------------+---------
 jeanneau     | foobar    | id         | private
(1 row)
```

The final goal of the extension is to make information on column
available to be crossed with information from other systems.

Here at Smartway we add comments on every field in Django Models with
[db_comment](https://docs.djangoproject.com/en/5.1/ref/models/fields/#db-comment)
and cross this information with the DBT doc generated.  As is
developpers can define the usability of every columns for data
analysts and follow what we call a Data Contract.

This extension is at early stage for now, we will extend the JSON
format in the following month.

## Free Software

We released this extension as a free software as it may be useful for
any other company with the same need.