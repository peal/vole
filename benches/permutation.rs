use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion};

use rust_peal::perm::Permutation;

pub fn inverse_of_product(c: &mut Criterion) {
    let mut group = c.benchmark_group("Inverse of Product");
    for i in [8, 16, 32, 64, 128, 256, 512].iter() {
        // TODO: This should probably be some random permutation
        let first = |i: usize| Permutation::from_vec((0..i).map(|x| (x + 1) % i).collect());
        let second = |i: usize| Permutation::from_vec((0..i).map(|x| (x + 5) % i).collect());
        group.bench_with_input(BenchmarkId::new("(a * b)^-1", i), i, |b, i| {
            let first = first(*i);
            let second = second(*i);
            b.iter(|| black_box(first.multiply(&second).inv()))
        });
        group.bench_with_input(BenchmarkId::new("b^-1 * a^-1", i), i, |b, i| {
            let first = first(*i);
            let second = second(*i);
            b.iter(|| black_box(second.inv().multiply(&first.inv())))
        });
    }
    group.finish();
}

criterion_group!(benches, inverse_of_product);
criterion_main!(benches);
