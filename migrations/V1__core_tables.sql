-- V1: core tables, constraints, relationships
CREATE TABLE tenants (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(120) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE app_users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id     BIGINT       NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email         VARCHAR(255) NOT NULL,
    password_hash TEXT         NOT NULL,
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('admin','analyst','customer')),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, email)
);

CREATE TABLE customers (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT       NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id     BIGINT       UNIQUE REFERENCES app_users(id) ON DELETE SET NULL,
    full_name   VARCHAR(150) NOT NULL,
    country     CHAR(2)      NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (id, tenant_id)            -- target for composite FKs: prevents cross-tenant references
);

CREATE TABLE categories (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id  BIGINT       NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name       VARCHAR(100) NOT NULL,
    parent_id  BIGINT       REFERENCES categories(id) ON DELETE SET NULL,
    UNIQUE (tenant_id, name),
    UNIQUE (id, tenant_id)
);

CREATE TABLE products (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id    BIGINT       NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    category_id  BIGINT       NOT NULL,
    sku          VARCHAR(40)  NOT NULL,
    name         VARCHAR(200) NOT NULL,
    price_cents  INTEGER      NOT NULL CHECK (price_cents >= 0),
    stock        INTEGER      NOT NULL CHECK (stock >= 0),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, sku),
    UNIQUE (id, tenant_id),
    FOREIGN KEY (category_id, tenant_id) REFERENCES categories (id, tenant_id)
);

CREATE TABLE orders (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id    BIGINT      NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id  BIGINT      NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','paid','shipped','delivered','cancelled')),
    total_cents  BIGINT      NOT NULL CHECK (total_cents >= 0),
    placed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    FOREIGN KEY (customer_id, tenant_id) REFERENCES customers (id, tenant_id)
);

CREATE TABLE order_items (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id         BIGINT  NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id       BIGINT  NOT NULL REFERENCES products(id),
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0)
);

CREATE TABLE payments (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      BIGINT      NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    method        VARCHAR(20) NOT NULL CHECK (method IN ('card','mpesa','paypal','bank')),
    amount_cents  BIGINT      NOT NULL CHECK (amount_cents > 0),
    paid_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE reviews (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id    BIGINT      NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id   BIGINT      NOT NULL,
    customer_id  BIGINT      NOT NULL,
    rating       SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (product_id, customer_id),
    FOREIGN KEY (product_id,  tenant_id) REFERENCES products  (id, tenant_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id, tenant_id) REFERENCES customers (id, tenant_id) ON DELETE CASCADE
);
