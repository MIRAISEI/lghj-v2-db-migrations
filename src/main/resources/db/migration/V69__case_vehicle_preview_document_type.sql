-- =============================================================================
-- Lets staff choose whether the customer-facing "CIF document" slot for a
-- vehicle shows the actual CIF document or the (differently-purposed) "LC"
-- document instead — some vehicles only have a document created against the
-- LC amount, which staff want to present to the customer in place of a CIF
-- document. Toggled from the Purchasing tab's "Preview to Customer" control.
-- =============================================================================

ALTER TABLE case_vehicles
    ADD COLUMN preview_document_type VARCHAR(10) NOT NULL DEFAULT 'CIF' COMMENT 'CIF or LC — which document is shown to the customer as the CIF document'
    AFTER lc_amount;
