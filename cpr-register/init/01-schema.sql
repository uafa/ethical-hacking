-- CPR-Register schema
-- Danish "Det Centrale Personregister" style citizen table.

CREATE TABLE citizens (
    id          SERIAL PRIMARY KEY,
    cpr         CHAR(11)     NOT NULL UNIQUE,   -- format DDMMYY-SSSS
    firstname   VARCHAR(100) NOT NULL,
    lastname    VARCHAR(100) NOT NULL,
    address     VARCHAR(200) NOT NULL,
    postal_code CHAR(4)      NOT NULL,
    city        VARCHAR(100) NOT NULL,
    phone       VARCHAR(20),
    gp_doctor   VARCHAR(120),                   -- assigned general practitioner
    registered  DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- An administrative notes table to make the dump look realistic.
CREATE TABLE audit_log (
    id         SERIAL PRIMARY KEY,
    actor      VARCHAR(100) NOT NULL,
    action     VARCHAR(200) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
