/* 
This procedure perform summarizing data statistic. 
It make profiling for every column of any given table in PostgreSQL Database. 
*/

DROP FUNCTION IF EXISTS get_column_stats();
CREATE OR REPLACE FUNCTION get_column_stats(p_table_name text) 
RETURNS TABLE (
  -- Returned table columns names
  "Table Name" text,
  "Column Name" information_schema.sql_identifier,
  "Data Type" text,
  "Min Value" numeric,
  "Max Value" numeric,
  "Avg Value" numeric,
  "Mode Value" text
)
AS $$
DECLARE
  -- Declaration of temporary veriables
  v_column_name information_schema.sql_identifier;
  v_data_type text;
  v_is_fk text;
  v_query text;
  v_min_value numeric;
  v_max_value numeric;
  v_avg_value numeric;
  v_mode_value text;
BEGIN
  -- Searching for all column names of the table
  FOR v_column_name IN 
    SELECT  c.COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS c
	-- Joining information about PRIMARY KEY konstraints of the column
	LEFT JOIN (
					SELECT ku.TABLE_CATALOG,ku.TABLE_SCHEMA,ku.TABLE_NAME,ku.COLUMN_NAME
					FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
					INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
						ON tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
						AND tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
			    ) pk ON  c.TABLE_CATALOG = pk.TABLE_CATALOG
				AND c.TABLE_SCHEMA = pk.TABLE_SCHEMA
				AND c.TABLE_NAME = pk.TABLE_NAME
				AND c.COLUMN_NAME = pk.COLUMN_NAME
	WHERE c.TABLE_NAME = p_table_name
	AND pk.COLUMN_NAME IS NULL -- exclude primary key
  LOOP
    -- Get the data type of the current column
    SELECT c.data_type, pk.COLUMN_NAME INTO v_data_type, v_is_fk -- Returning data type and NOT NULL in v_is_fk if column is a FOREIGN KEY
    FROM INFORMATION_SCHEMA.COLUMNS c
	LEFT JOIN (
				SELECT ku.TABLE_CATALOG,ku.TABLE_SCHEMA,ku.TABLE_NAME,ku.COLUMN_NAME
				FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
				INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
					ON tc.CONSTRAINT_TYPE = 'FOREIGN KEY' 
					AND tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
			 )   pk 
	ON  c.TABLE_CATALOG = pk.TABLE_CATALOG
				AND c.TABLE_SCHEMA = pk.TABLE_SCHEMA
				AND c.TABLE_NAME = pk.TABLE_NAME
				AND c.COLUMN_NAME = pk.COLUMN_NAME
	WHERE c.TABLE_NAME = p_table_name
    AND c.column_name = v_column_name;
    
    -- If the column's data type is numeric and is not an excluded column, calculate its statistics
    IF v_data_type IN ('integer', 'decimal', 'numeric', 'real', 'double precision', 'smallint') 
		AND v_is_fk IS NULL -- If column is a Foreign key it should not be measured as a number
		AND v_column_name NOT IN ('store_id', 'active', 'release_year')
	THEN
      -- Build the query to calculate the statistics and execute it
      v_query := 'SELECT MIN(' || v_column_name || '), MAX(' || v_column_name || '), AVG(' || v_column_name || '), NULL FROM ' || p_table_name || ';';
      EXECUTE v_query INTO v_min_value, v_max_value, v_avg_value;
      v_mode_value := NULL;
    ELSE -- If the column's data type is not numeric, or is a Foreign key - calculate its mode
      -- Build the query to calculate the mode and execute it
      v_query := 'SELECT MODE() WITHIN GROUP (ORDER BY ' || v_column_name || ') FROM ' || p_table_name || ';';
      EXECUTE v_query INTO v_mode_value;
      v_min_value := NULL;
      v_max_value := NULL;
      v_avg_value := NULL;
    END IF;
    
    -- Return the calculated statistics for the current column
    "Table Name" := p_table_name;
    "Column Name" := v_column_name;
    "Data Type" := v_data_type;
    "Min Value" := v_min_value;
    "Max Value" := v_max_value;
    "Avg Value" := v_avg_value;
    "Mode Value" := v_mode_value;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Call the function for the 'customer' and 'film' tables
SELECT * FROM get_column_stats('customer') 
UNION ALL
SELECT * FROM get_column_stats('film');

