CREATE TABLE IF NOT EXISTS errands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  reward REAL NOT NULL,
  description TEXT NOT NULL,
  time_to_complete TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('Open', 'Completed', 'Closed')) DEFAULT 'Open',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  poster_id TEXT,
  poster_name TEXT,
  runner_id TEXT,
  runner_name TEXT,
  accepted_at TEXT,
  is_seed INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  errand_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (errand_id) REFERENCES errands(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS errand_offers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  errand_id INTEGER NOT NULL,
  runner_id TEXT NOT NULL,
  runner_name TEXT NOT NULL,
  message TEXT NOT NULL,
  proposed_reward REAL NOT NULL,
  estimated_time TEXT NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('Pending', 'Accepted', 'Rejected', 'Withdrawn')
  ) DEFAULT 'Pending',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (errand_id, runner_id),
  FOREIGN KEY (errand_id) REFERENCES errands(id) ON DELETE CASCADE
);

INSERT INTO errands (
  title,
  reward,
  description,
  time_to_complete,
  status,
  created_at,
  poster_id,
  poster_name,
  is_seed
)
VALUES
  (
    'Simpan barang waktu cuti sem',
    85.00,
    'Pickup barang kat KHAR 4182, 9 Julai.',
    'Today before 5:00 PM',
    'Open',
    '2026-06-12T09:00:00.000',
    NULL,
    'UniMove',
    1
  ),
  (
    'Photostate slip exam',
    1.50,
    'Hantar kat KAHS block C .',
    'Within 2 hours',
    'Open',
    '2026-06-12T10:30:00.000',
    NULL,
    'UniMove',
    1
  ),
  (
    'Beli Abuya COD KHAR 4182',
    2.00,
    'Abuya ayam bahagian dada tambah kicap, extra sambal.',
    'By 1:30 PM',
    'Open',
    '2026-06-12T11:15:00.000',
    NULL,
    'UniMove',
    1
  ),
  (
    'Pinjam raket',
    10.00,
    'Nak main badminton 2 jam, nanti saya pulangkan.',
    'Before 7:00 PM',
    'Completed',
    '2026-06-11T16:45:00.000',
    NULL,
    'UniMove',
    1
  );
