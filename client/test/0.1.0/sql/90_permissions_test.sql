-- Use regular user role
SET ROLE test_regular_user;

-- Add to the search path the schema
SET search_path TO public,cartodb,cdb_geocoder_client;

-- Exercise the public function
-- it is public, it shall work
SELECT cdb_geocode_admin0_polygon('Spain');
SELECT cdb_geocode_admin1_polygon('California');
SELECT cdb_geocode_admin1_polygon('California', 'United States');
SELECT cdb_geocode_namedplace_point('Elx');
SELECT cdb_geocode_namedplace_point('Elx', 'Valencia');
SELECT cdb_geocode_namedplace_point('Elx', 'Valencia', 'Spain');
SELECT cdb_geocode_postalcode_polygon('03204', 'Spain');
SELECT cdb_geocode_postalcode_point('03204', 'Spain');
SELECT cdb_geocode_ipaddress_point('8.8.8.8');
SELECT cdb_geocode_street_point_v2('one street, 1');

-- Check the regular user has no permissions on private functions
SELECT _cdb_geocode_admin0_polygon('evil_user', 'evil_orgname', 'Hell');
SELECT _cdb_geocode_admin1_polygon('evil_user', 'evil_orgname', 'Hell');
SELECT _cdb_geocode_admin1_polygon('evil_user', 'evil_orgname', 'Sheol', 'Hell');
SELECT _cdb_geocode_namedplace_point('evil_user', 'evil_orgname', 'Sheol');
SELECT _cdb_geocode_namedplace_point('evil_user', 'evil_orgname', 'Sheol', 'Hell');
SELECT _cdb_geocode_namedplace_point('evil_user', 'evil_orgname', 'Sheol', 'Hell', 'Ugly world');
SELECT _cdb_geocode_postalcode_polygon('evil_user', 'evil_orgname', '66666', 'Hell');
SELECT _cdb_geocode_postalcode_point('evil_user', 'evil_orgname', '66666', 'Hell');
SELECT _cdb_geocode_ipaddress_point('evil_user', 'evil_orgname', '8.8.8.8');
SELECT _cdb_geocode_street_point_v2('evil_user', 'evil_orgname', 'one street, 1');
