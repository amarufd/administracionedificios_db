-- Pin trigger function search_path for app sessions that do not default to lazaro.
SET search_path TO lazaro, public;

ALTER FUNCTION lazaro.validate_common_expense_boiler_rules() SET search_path TO lazaro, public;
ALTER FUNCTION lazaro.validate_measurement_boiler_rules() SET search_path TO lazaro, public;
ALTER FUNCTION lazaro.protect_approved_expense_records() SET search_path TO lazaro, public;
ALTER FUNCTION lazaro.validate_common_expense_origin_and_publication() SET search_path TO lazaro, public;
ALTER FUNCTION lazaro.allocate_common_expense_concept() SET search_path TO lazaro, public;
