insert into public.errands (
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
select *
from (
  values
    (
      'Simpan barang waktu cuti sem',
      85.00,
      'Pickup barang kat KHAR 4182, 9 Julai.',
      'Today before 5:00 PM',
      'Open',
      '2026-06-12T09:00:00.000Z'::timestamptz,
      null::uuid,
      'UniMove',
      true
    ),
    (
      'Photostate slip exam',
      1.50,
      'Hantar kat KAHS block C .',
      'Within 2 hours',
      'Open',
      '2026-06-12T10:30:00.000Z'::timestamptz,
      null::uuid,
      'UniMove',
      true
    ),
    (
      'Beli Abuya COD KHAR 4182',
      2.00,
      'Abuya ayam bahagian dada tambah kicap, extra sambal.',
      'By 1:30 PM',
      'Open',
      '2026-06-12T11:15:00.000Z'::timestamptz,
      null::uuid,
      'UniMove',
      true
    ),
    (
      'Pinjam raket',
      10.00,
      'Nak main badminton 2 jam, nanti saya pulangkan.',
      'Before 7:00 PM',
      'Completed',
      '2026-06-11T16:45:00.000Z'::timestamptz,
      null::uuid,
      'UniMove',
      true
    )
) as seed_errands (
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
where not exists (
  select 1
  from public.errands
  where public.errands.is_seed = true
    and public.errands.title = seed_errands.title
    and public.errands.created_at = seed_errands.created_at
);
