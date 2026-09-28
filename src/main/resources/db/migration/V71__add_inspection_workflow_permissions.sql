-- V71: Inspection-failure resolution workflow permissions.
--
-- V66 created the inspection_attempts / inspection_resolutions / inspection_charges
-- tables and the admin-api added @PreAuthorize("hasAuthority('CASE_INSPECTION_MANAGE')")
-- / hasAuthority('CASE_CHARGE_VERIFY') to InspectionResolutionController, but the
-- two permissions were never seeded here. In every environment that runs with
-- DATA_INITIALIZATION_ENABLED=false (staging/prod, and the default), the Java
-- DataInitializer never runs, so NO role -- not even ADMIN -- carried these
-- authorities and every inspection-workflow endpoint returned 403 "access denied".
--
--  - CASE_INSPECTION_MANAGE: record inspection attempts + remark/report, choose the
--    re-inspect / fix-and-reinspect / re-auction path, set fix-cost / re-auction-loss
--    amounts, mark a fix complete. Logistics-side, mirrors CASE_LOGISTICS_MANAGE.
--  - CASE_CHARGE_VERIFY: verify the customer's fix-cost / re-auction-loss payment
--    proof. Finance-side, mirrors CASE_DEPOSIT_VERIFY / CASE_LC_VERIFY.

INSERT IGNORE INTO permissions (id, name) VALUES
    (UUID(), 'CASE_INSPECTION_MANAGE'),
    (UUID(), 'CASE_CHARGE_VERIFY');

-- ADMIN always gets every permission.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

-- SHIPPING manages the logistics area (Transport / Inspection / Shipping tabs) --
-- it already holds CASE_LOGISTICS_MANAGE + CASE_SHIPPING_MANAGE.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'CASE_INSPECTION_MANAGE'
WHERE r.name = 'SHIPPING';

-- FINANCE verifies payment proofs -- it already holds CASE_DEPOSIT_VERIFY +
-- CASE_LC_VERIFY.
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'CASE_CHARGE_VERIFY'
WHERE r.name = 'FINANCE';
