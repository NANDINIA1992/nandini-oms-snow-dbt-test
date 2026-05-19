
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
  -----------create fileformat--------------

CREATE OR REPLACE FILE FORMAT AWS_INT.file_formats.csv_fileformat
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

----------------create external stage------------

CREATE OR REPLACE STAGE AWS_INT.external_stages.csv_folder
    URL = 's3://vitechsnow21/csv/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = AWS_INT.file_formats.csv_fileformat;    



    

LIST @AWS_INT.external_stages.csv_folder;


-----------------create employee table-----------

CREATE OR REPLACE TABLE AWS_INT.PUBLIC.employee_data (
  id STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  location STRING,
  department STRING
);

---------------------create SNOWPIPE for auto ingest----------------

CREATE OR REPLACE PIPE AWS_INT.PUBLIC.employee_data_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO AWS_INT.PUBLIC.employee_data
    FROM @AWS_INT.external_stages.csv_folder
    PATTERN = '.*employee.*[.]csv'
    ON_ERROR= CONTINUE;

-- Get the SQS ARN (notification_channel) for this pipe
SHOW PIPES LIKE 'employee_data_pipe' IN AWS_INT.PUBLIC;

-- Pause pipe temporarily
ALTER PIPE AWS_INT.PUBLIC.employee_data_pipe SET PIPE_EXECUTION_PAUSED = TRUE;

-- Resume pipe
ALTER PIPE AWS_INT.PUBLIC.employee_data_pipe SET PIPE_EXECUTION_PAUSED = FALSE;

-- Refresh pipe (force re-processing)
ALTER PIPE AWS_INT.PUBLIC.employee_data_pipe REFRESH;

---------------------
SHOW PIPES LIKE 'employee_data_pipe' IN AWS_INT.PUBLIC;
-----------view pipe status----------
SELECT SYSTEM$PIPE_STATUS('AWS_INT.PUBLIC.movie_titles_pipe');

------------view table data-------------

select * from AWS_INT.PUBLIC.employee_data;
