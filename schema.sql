
CREATE TABLE IF NOT EXISTS metrics (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_name VARCHAR(255) NOT NULL COLLATE utf8_bin,
    section_name VARCHAR(255) NOT NULL COLLATE utf8_bin,
    graph_name   VARCHAR(255) NOT NULL COLLATE utf8_bin,
    sort         INT UNSIGNED NOT NULL DEFAULT 0,
    meta         TEXT NOT NULL,
    created_at   DATETIME NOT NULL,
    updated_at   TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY (service_name, section_name, graph_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS data (
    metrics_id    INT UNSIGNED NOT NULL,
    datetime     DATETIME NOT NULL,
    number       BIGINT NOT NULL,
    updated_at   TIMESTAMP NOT NULL,
    PRIMARY KEY (metrics_id, datetime),
    KEY (datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS complex (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_name VARCHAR(255) NOT NULL COLLATE utf8_bin,
    section_name VARCHAR(255) NOT NULL COLLATE utf8_bin,
    graph_name   VARCHAR(255) NOT NULL COLLATE utf8_bin,
    sort         INT UNSIGNED NOT NULL DEFAULT 0,
    meta         TEXT NOT NULL,
    created_at   DATETIME NOT NULL,
    updated_at   TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY (service_name, section_name, graph_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

