CREATE TABLE errands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  reward REAL NOT NULL,
  description TEXT NOT NULL,
  time_to_complete TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('Open', 'Completed', 'Closed')) DEFAULT 'Open',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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
