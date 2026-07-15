# Patterns

> Read when writing a provider, repository, use case, form, or navigation call.

## Provider

```dart
class CartProvider extends ChangeNotifier {
  final FetchCartUseCase _fetchCart;
  CartProvider({required FetchCartUseCase fetchCart}) : _fetchCart = fetchCart;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchCart();
    result.fold(
      (failure) => _error = failure.message,
      (items) => _items = items,
    );

    _isLoading = false;
    notifyListeners();
  }
}
```

## Consumer (scoped rebuild)

```dart
Consumer<CartProvider>(
  builder: (context, cart, _) {
    if (cart.isLoading) return const AppLoadingIndicator();
    if (cart.error != null) return AppErrorView(message: cart.error!);
    return CartList(items: cart.items);
  },
)

// One-time read in a callback only
onPressed: () => context.read<CartProvider>().fetchCart();
```

## Registering providers in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
      create: (ctx) => CartProvider(
        fetchCart: FetchCartUseCase(ctx.read<CartRepository>()),
      ),
      update: (_, auth, previous) => previous!..onAuthChanged(auth),
    ),
  ],
  child: const MyApp(),
)
```

## Repository

```dart
// domain — abstract
abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> fetchCart();
}

// data — concrete
class CartRepositoryImpl implements CartRepository {
  final CartRemoteSource _remote;
  CartRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<CartItem>>> fetchCart() async {
    try {
      final models = await _remote.getCart();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

## Use case

```dart
class FetchCartUseCase {
  final CartRepository _repo;
  const FetchCartUseCase(this._repo);
  Future<Either<Failure, List<CartItem>>> call() => _repo.fetchCart();
}
```

## JSON model

```dart
class CartItemModel {
  final String id;
  final int quantity;

  const CartItemModel({required this.id, required this.quantity});

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'] as String,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity};

  CartItem toEntity() => CartItem(id: id, quantity: quantity);
}
```

## Navigation

```dart
context.go('/cart');          // replaces stack — use for tabs/root
context.push('/product/$id'); // adds to stack — use when back is needed
context.pop();
```

## Form

```dart
class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }
}
```
