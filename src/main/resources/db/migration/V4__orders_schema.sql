
CREATE TABLE IF NOT EXISTS orders (
    id CHAR(36) NOT NULL,
    slug VARCHAR(255) NULL,
    user_id CHAR(36) NOT NULL,
    tax DECIMAL(16,2) NULL,
    shipping DECIMAL(16,2) NULL,
    total DECIMAL(16,2) NULL,
    status INT NOT NULL,
    deleted_at DATETIME(6) NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_orders_user_id ON orders (user_id);


CREATE TABLE IF NOT EXISTS order_items (
    id CHAR(36) NOT NULL,
    slug VARCHAR(255) NULL,
    order_id CHAR(36) NOT NULL,
    amount DECIMAL(16,2) NULL,
    status INT NOT NULL,
    type INT NOT NULL,
    qty INT NOT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id)
);

CREATE INDEX idx_order_items_order_id ON order_items (order_id);

CREATE TABLE IF NOT EXISTS order_statuses (
    id CHAR(36) NOT NULL,
    order_id CHAR(36) NOT NULL,
    user_id CHAR(36) NULL,
    status INT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    CONSTRAINT pk_order_statuses PRIMARY KEY (id),
    CONSTRAINT fk_order_statuses_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_order_statuses_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_order_statuses_order_id ON order_statuses (order_id);

CREATE TABLE IF NOT EXISTS order_item_statuses (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NULL,
    order_item_id CHAR(36) NOT NULL,
    status INT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    CONSTRAINT pk_order_item_statuses PRIMARY KEY (id),
    CONSTRAINT fk_order_item_statuses_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id),
    CONSTRAINT fk_order_item_statuses_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_order_item_statuses_order_item_id ON order_item_statuses (order_item_id);

CREATE TABLE IF NOT EXISTS order_documents (
    id CHAR(36) NOT NULL,
    order_id CHAR(36) NULL,
    name VARCHAR(255) NULL,
    path VARCHAR(255) NULL,
    type INT NOT NULL,
    status INT NOT NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    CONSTRAINT pk_order_documents PRIMARY KEY (id),
    CONSTRAINT fk_order_documents_order FOREIGN KEY (order_id) REFERENCES orders (id)
);
