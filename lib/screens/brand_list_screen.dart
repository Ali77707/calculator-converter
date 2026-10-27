import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_repository.dart';
import '../widgets/crud_list_page.dart';

class BrandListScreen extends StatelessWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudListPage<Brand>(
      title: 'Марки автомобилей',
      addLocation: '/brands/new',
      searchHint: 'Поиск по названию или стране',
      load: () => context.read<BrandRepository>().findAll(includeDeleted: true),
      idOf: (brand) => brand.id,
      titleOf: (brand) => brand.name,
      subtitleOf: (brand) => 'Страна: ${brand.country}',
      searchText: (brand) => '${brand.name} ${brand.country}',
      isDeleted: (brand) => brand.isDeleted,
      detailLocation: (brand) => '/brands/${brand.id}',
      editLocation: (brand) => '/brands/${brand.id}/edit',
      emptyMessage: 'Марки пока не добавлены',
      onSoftDelete: (id) async {
        final carRepository = context.read<CarRepository>();
        final brandRepository = context.read<BrandRepository>();
        final count = await carRepository.countByMake(id);
        if (count > 0) {
          throw StateError(
            'марка используется в $count автомобилях. '
            'Сначала измените или удалите эти автомобили.',
          );
        }
        await brandRepository.softDelete(id);
      },
      onHardDelete: (id) async {
        final carRepository = context.read<CarRepository>();
        final brandRepository = context.read<BrandRepository>();
        final count = await carRepository.countByMake(id);
        if (count > 0) {
          throw StateError(
            'марка используется в $count автомобилях. '
            'Удаление невозможно.',
          );
        }
        await brandRepository.hardDelete(id);
      },
      onRestore: (id) => context.read<BrandRepository>().restore(id),
    );
  }
}
