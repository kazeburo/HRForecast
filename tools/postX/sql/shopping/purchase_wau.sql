select
    wau_log.dt as dt,
    wau_new,
    retention,
    resurrection,
    total,
    all
from (
    select
        to_char(NOW() + INTERVAL '-1 DAY', 'YYYY-MM-DD')                                as dt,
        sum(case when last_week is null and before_last_week is null then 1 else 0 end) as wau_new,
        sum(case when last_week = 1 then 1 else 0 end)                                  as retention,
        sum(case when last_week is null and before_last_week = 1 then 1 else 0 end)     as resurrection,
        count(*)                                                                        as total
    from (
        select
            this_week_log.user_id,
            this_week,
            last_week,
            before_last_week
        from (
            select
                distinct user_id,
                1 as this_week
            from
                SHOPPING_PURCHASE_LOG
            where
                status = 3
            and
                fished_at >= to_char(next_day(NOW() - interval '8 day', 'mon'), 'YYYY-MM-DD')
            and
                fished_at <  to_char(NOW(), 'YYYY-MM-DD')
        ) as this_week_log
    
        left join (
            select
                distinct user_id,
                1 as last_week
            from
                SHOPPING_PURCHASE_LOG
            where
                status = 3
            and
                fished_at >= to_char(next_day(NOW() - interval '15 day', 'mon'), 'YYYY-MM-DD')
            and
                fished_at <  to_char(next_day(NOW() - interval '8 day', 'mon'), 'YYYY-MM-DD')
        ) as last_week_log
        on
            this_week_log.user_id = last_week_log.user_id
    
        left join (
            select
                distinct user_id,
                1 as before_last_week
            from
                SHOPPING_PURCHASE_LOG
            where
                status = 3
            and
                fished_at <  to_char(next_day(NOW() - interval '15 day', 'mon'), 'YYYY-MM-DD')
        ) as before_last_week_log
        on
            this_week_log.user_id = before_last_week_log.user_id    
    ) as log
) as wau_log

join (
    select
        to_char(NOW() + INTERVAL '-1 DAY', 'YYYY-MM-DD') as dt,
        count(*)                                         as all_active
    from (
        select
            user_id,
            count(*) days_cnt
        from (
            select
                distinct user_id,
                to_char(fished_at, 'YYYY-MM-DD') as ymd
            from
                SHOPPING_PURCHASE_LOG
            where
                status = 3
            and
                fished_at >= to_char(next_day(NOW() - interval '8 day', 'mon'), 'YYYY-MM-DD')
            and
                fished_at <  to_char(NOW(), 'YYYY-MM-DD')
            order by
                user_id
        ) as log
        group by
            user_id
        order by
            days_cnt desc
    ) as fish_log
    group by
        days_cnt
    having
        days_cnt = (case when to_char(NOW(), 'D') >= 3 then to_char(NOW(), 'D') - 2 else to_char(NOW(), 'D') + 5 end) 
) as active_log
on wau_log.dt = active_log.dt
