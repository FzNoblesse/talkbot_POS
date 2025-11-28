import 'package:flutter/material.dart';
import 'database_helper.dart';

class PantallaInventario extends StatefulWidget {
  const PantallaInventario({super.key});

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  List<Map<String, dynamic>> _productos = [];
  final TextEditingController _searchController = TextEditingController();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  // Carga los primeros 50 productos para no saturar
  void _cargarInicial() async {
    setState(() => _cargando = true);
    final datos = await DatabaseHelper().obtenerProductos(limite: 50);
    setState(() {
      _productos = datos;
      _cargando = false;
    });
  }

  // Buscar en tiempo real
  void _buscar(String texto) async {
    if (texto.isEmpty) {
      _cargarInicial();
      return;
    }
    final datos = await DatabaseHelper().buscarPorNombre(texto);
    setState(() {
      _productos = datos;
    });
  }

  // --- VENTANA PARA AGREGAR / EDITAR ---
  void _abrirEditor({Map<String, dynamic>? productoExistente}) {
    final codigoCtrl = TextEditingController(
      text: productoExistente?['codigo'] ?? '',
    );
    final descCtrl = TextEditingController(
      text: productoExistente?['descripcion'] ?? '',
    );
    final precioCtrl = TextEditingController(
      text: productoExistente?['precio_venta']?.toString() ?? '0',
    );
    final costoCtrl = TextEditingController(
      text: productoExistente?['precio_compra']?.toString() ?? '0',
    );
    final stockCtrl = TextEditingController(
      text: productoExistente?['stock']?.toString() ?? '0',
    );

    // Si es nuevo, permitimos editar código. Si existe, bloqueamos el código.
    bool esNuevo = productoExistente == null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esNuevo ? "Nuevo Producto" : "Editar Producto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                decoration: const InputDecoration(
                  labelText: "Código de Barras",
                  prefixIcon: Icon(Icons.qr_code),
                ),
                enabled: esNuevo, // Solo editable si es nuevo
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre / Descripción",
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Costo (\$)",
                        prefixIcon: Icon(Icons.money_off),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Venta (\$)",
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock Actual",
                  prefixIcon: Icon(Icons.warehouse),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!esNuevo)
            TextButton(
              onPressed: () async {
                // Confirmar borrado
                bool confirmar =
                    await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("¿Eliminar?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text("SÍ"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text("No"),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (!mounted) return;

                if (confirmar) {
                  await DatabaseHelper().eliminarProducto(
                    productoExistente['codigo'],
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  _buscar(_searchController.text); // Refrescar lista

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Producto eliminado")),
                  );
                }
              },
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Guardar cambios
          ElevatedButton(
            onPressed: () async {
              final nuevoProd = {
                'codigo': codigoCtrl.text,
                'descripcion': descCtrl.text,
                'precio_venta': double.tryParse(precioCtrl.text) ?? 0,
                'precio_compra': double.tryParse(costoCtrl.text) ?? 0,
                'stock': int.tryParse(stockCtrl.text) ?? 0,
                'es_retornable': 0, // Pendiente
              };

              if (esNuevo) {
                await DatabaseHelper().crearProducto(nuevoProd);
              } else {
                await DatabaseHelper().actualizarProducto(
                  nuevoProd['codigo'].toString(),
                  nuevoProd['precio_venta'] as double,
                  nuevoProd['stock'] as int,
                  0,
                );
                // Nota: Tu función actualizarProducto actualiza solo 3 campos,
                // si quieres actualizar descripción o costo, deberías mejorar esa función en el Helper.
              }

              if (!mounted) return;

              Navigator.pop(context);
              _buscar(_searchController.text); // Refrescar lista

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Guardado correctamente")),
              );
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario y Almacén"),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirEditor(), // Abrir vacío para crear nuevo
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar producto para editar...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _cargarInicial();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _buscar,
            ),
          ),

          // LISTA DE PRODUCTOS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final item = _productos[index];
                      final stock = item['stock'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: stock <= 2
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            child: Icon(
                              Icons.inventory_2,
                              color: stock <= 2 ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(
                            item['descripcion'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Costo: \$${item['precio_compra'] ?? 0}  |  Venta: \$${item['precio_venta']}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$stock",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: stock <= 2 ? Colors.red : Colors.black,
                                ),
                              ),
                              const Text(
                                "Stock",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _abrirEditor(productoExistente: item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
