with temp_check as (
    select
        country,
        temp_start_year,
        temp_end_year,
        total_increase
    from {{ ref('fact_temp_increase_ranking') }}
)

select *
from temp_check
where total_increase > 10
   or total_increase < -10
   or abs((temp_end_year - temp_start_year) - total_increase) > 0.001