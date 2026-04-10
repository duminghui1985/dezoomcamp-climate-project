with range_check as (
    select
        min(extract(year from record_date)) as min_year,
        max(extract(year from record_date)) as max_year
    from {{ ref('fact_climate_population') }}
)

select *
from range_check
where 
    min_year != {{ var('project_start_year') }}
    
    or max_year < {{ var('current_expected_end_year') }}
    
    or min_year is null