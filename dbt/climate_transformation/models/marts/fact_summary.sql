select
    min(record_date) as start_date,
    max(record_date) as end_date,
    count(distinct country_code) as total_countries,
    count(*) as total_records,
    date_diff(max(record_date), min(record_date), YEAR) + 1 as total_years
from {{ ref('fact_climate_population') }}