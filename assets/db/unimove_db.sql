CREATE TABLE user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('Student', 'Runner')) DEFAULT 'Student',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO user (name, email, password_hash, phone_number, role)
VALUES
('Indra Petra', 'indra@mail.com', 'hashed_password_here', '061069', 'Student');

CREATE TABLE errands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  reward REAL NOT NULL,
  description TEXT NOT NULL,
  time_to_complete TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('Open', 'Completed', 'Closed')) DEFAULT 'Open',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE password_resets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  reset_token TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id)
);

INSERT INTO errands (title, reward, description, time_to_complete, status, created_at)
VALUES
  (
    'Simpan barang waktu cuti sem',
    85.00,
    'Pickup barang kat KHAR 4182, 9 Julai.',
    'Today before 5:00 PM',
    'Open',
    '2026-06-12T09:00:00.000'
  ),
  (
    'Photostate slip exam',
    1.50,
    'Hantar kat KAHS block C .',
    'Within 2 hours',
    'Open',
    '2026-06-12T10:30:00.000'
  ),
  (
    'Beli Abuya COD KHAR 4182',
    2.00,
    'Abuya ayam bahagian dada tambah kicap, extra sambal.',
    'By 1:30 PM',
    'Open',
    '2026-06-12T11:15:00.000'
  ),
  (
    'Pinjam raket',
    10.00,
    'Nak main badminton 2 jam, nanti saya pulangkan.',
    'Before 7:00 PM',
    'Completed',
    '2026-06-11T16:45:00.000'
  );

