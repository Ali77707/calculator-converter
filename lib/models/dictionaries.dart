class NamedOption {
  final int id;
  final String name;

  const NamedOption(this.id, this.name);
}

const List<NamedOption> makes = [
  NamedOption(1, 'Toyota'),
  NamedOption(2, 'BMW'),
  NamedOption(3, 'Audi'),
  NamedOption(4, 'Volkswagen'),
  NamedOption(5, 'Hyundai'),
  NamedOption(6, 'Kia'),
  NamedOption(7, 'Lada'),
  NamedOption(8, 'Mercedes-Benz'),
  NamedOption(9, 'Mazda'),
  NamedOption(10, 'Ford'),
];

const List<NamedOption> bodyTypes = [
  NamedOption(1, 'Седан'),
  NamedOption(2, 'Хэтчбек'),
  NamedOption(3, 'Универсал'),
  NamedOption(4, 'Кроссовер'),
  NamedOption(5, 'Внедорожник'),
  NamedOption(6, 'Купе'),
  NamedOption(7, 'Минивэн'),
  NamedOption(8, 'Фургон'),
];

const List<String> fuelTypes = ['Бензин', 'Дизель', 'Гибрид', 'Электро'];

const List<String> clientCities = [
  'Москва',
  'Санкт-Петербург',
  'Казань',
  'Екатеринбург',
  'Новосибирск',
  'Ростов-на-Дону',
  'Краснодар',
];

String makeName(int id) => makes
    .firstWhere((o) => o.id == id, orElse: () => const NamedOption(0, '—'))
    .name;

String bodyTypeName(int id) => bodyTypes
    .firstWhere((o) => o.id == id, orElse: () => const NamedOption(0, '—'))
    .name;
