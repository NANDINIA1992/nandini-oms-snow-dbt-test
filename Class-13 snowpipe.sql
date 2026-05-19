
--- AWS account id 479925391880

----canoncial user id 90cb90e8feaea990d127871d7c59b86a6fd3eb7eb68f073c814ccced9f7fe27f
CREATE OR REPLACE  DATABASE AWS_INT;

----1.CREATE S3 INTEGRATION---------

CREATE OR REPLACE STORAGE INTEGRATION s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::479925391880:role/vitechsnows3-role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://vitechsnow21/csv/', 's3://vitechsnow21/json/');



  DESCRIBE INTEGRATION s3_int;


  create OR REPLACE schema file_formats;

  create  OR REPLACE schema external_stages;

CREATE OR REPLACE FILE FORMAT AWS_INT.file_formats.csv_fileformat
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';



CREATE OR REPLACE STAGE AWS_INT.external_stages.csv_folder
    URL = 's3://vitechsnow21/csv/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = AWS_INT.file_formats.csv_fileformat;    



    

LIST @AWS_INT.external_stages.csv_folder;


-----------------

CREATE OR REPLACE TABLE AWS_INT.PUBLIC.movie_titles (
  show_id STRING,
  type STRING,
  title STRING,
  director STRING,
  cast STRING,
  country STRING,
  date_added STRING,
  release_year STRING,
  rating STRING,
  duration STRING,
  listed_in STRING,
  description STRING
);

---------------------create SNOWPIPE for auto ingest----------------

CREATE OR REPLACE PIPE AWS_INT.PUBLIC.movie_titles_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO AWS_INT.PUBLIC.movie_titles
    FROM @AWS_INT.external_stages.csv_folder
    pattern='.*netflix.*[.]csv'
    on_error=continue;
----------------------    
describe pipe AWS_INT.PUBLIC.movie_titles_pipe;   

---SHOW PIPES IN AWS_INT.PUBLIC;

SELECT SYSTEM$PIPE_STATUS('AWS_INT.PUBLIC.movie_titles_pipe');
------------copy data from s3 one time manually-------------

---COPY INTO AWS_INT.PUBLIC.movie_titles
---    FROM @AWS_INT.external_stages.csv_folder;

------------refresh the snowpipe-------------
-- Pause pipe temporarily
ALTER PIPE AWS_INT.PUBLIC.movie_titles_pipe SET PIPE_EXECUTION_PAUSED = TRUE;

-- Resume pipe
ALTER PIPE AWS_INT.PUBLIC.movie_titles_pipe SET PIPE_EXECUTION_PAUSED = FALSE;

-- Refresh pipe (force re-processing)
ALTER PIPE AWS_INT.PUBLIC.movie_titles_pipe REFRESH;

---------------------
SHOW PIPES LIKE 'movie_titles_pipe' IN AWS_INT.PUBLIC;
-----------view pipe status----------
SELECT SYSTEM$PIPE_STATUS('AWS_INT.PUBLIC.movie_titles_pipe');


    -- Verify loaded data
SELECT * FROM AWS_INT.PUBLIC.movie_titles LIMIT 10;

SELECT * FROM AWS_INT.PUBLIC.movie_titles;

