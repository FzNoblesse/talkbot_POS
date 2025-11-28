import 'package:flutter/material.dart';
import 'database_helper.dart';

class PantallaPosMinimalista extends StatefulWidget {
  final VoidCallback onSalir;

  const PantallaPosMinimalista({super.key, required this.onSalir});

  @override
  State<PantallaPosMinimalista> createState() => _PantallaPosMinimalistaState();
}

class _PantallaPosMinimalistaState extends State<PantallaPosMinimalista> {
  // --- VARIABLES ---
  final List<Map<String, dynamic>> _carrito = [];
  final TextEditingController _comandoController = TextEditingController();
  final FocusNode _comandoFocus = FocusNode();

  double _totalVenta = 0.0;
  int _cantidadPendiente = 1;
  String _clienteActual = "Público General";

  @override
  void initState() {
    super.initState();
    // Mantiene el foco en el lector de códigos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_comandoFocus);
    });
  }

  // 1. Procesar
  void _procesarComando(String valor) async {
    if (valor.isEmpty) return;
    if (valor.endsWith('*')) {
      int? cant = int.tryParse(valor.replaceAll('*', ''));
      if (cant != null && cant > 0) {
        setState(() => _cantidadPendiente = cant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Multiplicador: x$_cantidadPendiente"), duration: const Duration(milliseconds: 800), backgroundColor: Colors.orange)
        );
        _comandoController.clear();
        return;
      }
    }

    // Buscar producto
    final resultados = await DatabaseHelper().buscarPorNombre(valor);
    if (!mounted) return;

    if (resultados.isNotEmpty) {
      _agregarAlCarrito(resultados.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto no encontrado ❌"), backgroundColor: Colors.redAccent)
      );
    }
    _comandoController.clear();
    _comandoFocus.requestFocus();
  }

  // 2. Agregar al carrito
  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      int indice = _carrito.indexWhere((p) => p['codigo'] == producto['codigo']);
      if (indice != -1) {
        _carrito[indice]['cantidad'] += _cantidadPendiente;
      } else {
        Map<String, dynamic> item = Map.from(producto);
        item['precio_venta'] = item['precio_venta'] ?? 0.0;
        item['stock'] = item['stock'] ?? 0; // Aseguramos que traiga stock
        item['cantidad'] = _cantidadPendiente;
        _carrito.add(item);
      }
      _calcularTotal();
      _cantidadPendiente = 1; 
    });
  }

  // 3. Modificar Cantidad
  void _modificarCantidad(int index, int delta) {
    setState(() {
      _carrito[index]['cantidad'] += delta;
      if (_carrito[index]['cantidad'] <= 0) {
        _carrito.removeAt(index);
      }
      _calcularTotal();
    });
  }

  // 4. Calcular Total
  void _calcularTotal() {
    double temp = 0;
    for (var item in _carrito) {
      temp += (item['precio_venta'] * item['cantidad']);
    }
    setState(() {
      _totalVenta = temp;
    });
  }

  // 5. Editar Precio/Stock (Doble Clic)
  void _mostrarEditorPrecio(Map<String, dynamic> itemCarrito, int index) {
    final precioController = TextEditingController(text: itemCarrito['precio_venta'].toString());
    final stockController = TextEditingController(text: (itemCarrito['stock'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar: ${itemCarrito['descripcion']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Precio Venta", prefixIcon: Icon(Icons.attach_money)),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock", prefixIcon: Icon(Icons.warehouse)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                double nuevoPrecio = double.tryParse(precioController.text) ?? 0.0;
                int nuevoStock = int.tryParse(stockController.text) ?? 0;

                // Guardar en BD
                await DatabaseHelper().actualizarProducto(
                  itemCarrito['codigo'], nuevoPrecio, nuevoStock, 0
                );

                // Actualizar visualmente
                setState(() {
                  _carrito[index]['precio_venta'] = nuevoPrecio;
                  _carrito[index]['stock'] = nuevoStock;
                  _calcularTotal();
                });
                if(context.mounted) Navigator.pop(context);
              },
              child: const Text("Guardar"),
            )
          ],
        );
      },
    );
  }

  // 6. Botón Buscar
  void _accionBuscar(){
    _comandoFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escribe el nombre del producto..."), duration: Duration(seconds: 1)));
  }

// 7. Botón STOCK
  void _accionStock() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Verificador de precios"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.price_check, size: 50, color: Colors.purple),
              const SizedBox(height: 10),
              const Text("Escribe un código para ver precio y stock:"),
              const SizedBox(height: 10),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Código..."),
                textInputAction: TextInputAction.search,
                onSubmitted: (val) {
                  _procesarVerificacion(val, dialogContext);
                },
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Cerrar")
            )
          ],
        );
      },
    );
  }
  void _procesarVerificacion(String codigo, BuildContext dialogContext) async {
    final res = await DatabaseHelper().buscarPorNombre(codigo);
    if (!mounted) return;
    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
    if (res.isNotEmpty) {
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: Text(res.first['descripcion']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Precio: \$${res.first['precio_venta']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
               const SizedBox(height: 5),
               Text("Stock: ${res.first['stock']} unidades", style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        )
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Producto no encontrado"), backgroundColor: Colors.orange)
       );
    }
  }

  // 8. Botón Cliente
void _accionCliente() {
    TextEditingController clienteCtrl = TextEditingController(text: _clienteActual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Asignar Cliente"),
        content: TextField(
          controller: clienteCtrl,
          decoration: const InputDecoration(labelText: "Nombre del Cliente", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              setState(() => _clienteActual = clienteCtrl.text);
              Navigator.pop(ctx);
            }, 
            child: const Text("Asignar")
          )
        ],
      ),
    );
  }

  // 9. Finalizar Venta
  void _mostrarVentanaCobro() {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a usar los botones
      builder: (context) {
        double montoRecibido = 0.0;
        double cambio = 0.0;
        final pagoCtrl = TextEditingController();

        // StatefulBuilder permite que solo el dialog se actualice al escribir
        return StatefulBuilder(
          builder: (context, setStateModal) {
            void calcular(String val) {
              double pago = double.tryParse(val) ?? 0.0;
              setStateModal(() {
                montoRecibido = pago;
                cambio = pago - _totalVenta;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text("Finalizar venta", style: TextStyle(fontWeight: FontWeight.bold))),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resumen Total
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          const Text("Total a pagar", style: TextStyle(color: Colors.grey)),
                          Text("\$${_totalVenta.toStringAsFixed(2)}", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Input de Pago
                    TextField(
                      controller: pagoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(fontSize: 24),
                      decoration: const InputDecoration(
                        labelText: "Pago con...",
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: calcular,
                    ),

                    const SizedBox(height: 10),
                    // Botones rápidos de billetes
                    Wrap(
                      spacing: 8,
                      children: [20, 50, 100, 200, 500].map((b) => ActionChip(
                        label: Text("\$$b"),
                        onPressed: () {
                          pagoCtrl.text = b.toString();
                          calcular(b.toString());
                        },
                      )).toList(),
                    ),

                    const Divider(height: 30),

                    // Resultado Cambio
                    if (montoRecibido > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cambio >= 0 ? "CAMBIO: " : "FALTA: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("\$${cambio.abs().toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: cambio >= 0 ? Colors.green : Colors.red)),
                        ],
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancelar", style: TextStyle(color: Colors.red))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                  ),
                  // Solo habilita el botón si alcanza el dinero
                  onPressed: (montoRecibido >= _totalVenta) 
                    ? () {
                        // 1. CERRAR MODAL
                        Navigator.pop(context);
                        // 2. EJECUTAR GUARDADO
                        _finalizarVenta(montoRecibido, cambio);
                      } 
                    : null,
                  child: const Text("CONFIRMAR PAGO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _finalizarVenta(double pago, double cambio) async {
    // Guardar en BD
    try {
      await DatabaseHelper().insertarVenta(_totalVenta, "Efectivo", 1, _carrito);
      
      // Mostrar ticket visual rápido
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Venta Guardada. Cambio: \$${cambio.toStringAsFixed(2)}"),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        )
      );

      // Limpiar todo
      setState(() {
        _carrito.clear();
        _totalVenta = 0;
        _clienteActual = "Público General";
      });
      _comandoFocus.requestFocus(); // Regresar foco al scanner

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

// --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    final colorPrimario = Colors.indigo.shade600;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // HEADER
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: colorPrimario),
                    const SizedBox(width: 10),
                    Text("Punto de Venta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 16, color: colorPrimario),
                          const SizedBox(width: 5),
                          Text("Admin", style: TextStyle(color: colorPrimario, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- IZQUIERDA (65%) ---
                  Expanded(
                    flex: 65,
                    child: Column(
                      children: [
                        // Buscador
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:  0.05), blurRadius: 10)]),
                          child: TextField(
                            controller: _comandoController,
                            focusNode: _comandoFocus,
                            onSubmitted: _procesarComando,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: _cantidadPendiente > 1 ? "Escanea (x$_cantidadPendiente)..." : "Código o nombre...",
                              prefixIcon: Icon(Icons.qr_code_scanner, color: _cantidadPendiente > 1 ? Colors.orange : colorPrimario),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tabla
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Container(
                                  color: Colors.grey.shade100,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    children: const [
                                      Expanded(flex: 4, child: Text("PRODUCTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                                      Expanded(flex: 1, child: Text("PRECIO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                                      Expanded(flex: 2, child: Center(child: Text("CANT.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)))),
                                      Expanded(flex: 1, child: Text("TOTAL", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _carrito.isEmpty 
                                    ? Center(child: Text("Carrito vacío", style: TextStyle(color: Colors.grey.shade400)))
                                    : ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: _carrito.length,
                                        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16, endIndent: 16),
                                        itemBuilder: (context, index) {
                                          return _RenglonCarrito(
                                            item: _carrito[index],
                                            onSumar: () => _modificarCantidad(index, 1),
                                            onRestar: () => _modificarCantidad(index, -1),
                                            onEditar: () => _mostrarEditorPrecio(_carrito[index], index), // Define si quieres usar esta
                                          );
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // --- DERECHA (35%) ---
                  Expanded(
                    flex: 35,
                    child: Column(
                      children: [
                        // Tarjeta Cliente (Nuevo)
                        if (_clienteActual != "Público General")
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade200)),
                            child: Text("Cliente: $_clienteActual", textAlign: TextAlign.center, style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold)),
                          ),

                        // Total
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [colorPrimario, Colors.indigo.shade400]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: colorPrimario.withValues(alpha:  0.3), blurRadius: 15, offset: const Offset(0, 8))]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total a Pagar", style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 5),
                              Text("\$${_totalVenta.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón COBRAR (Ahora abre modal)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _carrito.isEmpty ? null : _mostrarVentanaCobro, // <--- CONECTADO
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("COBRAR (F12)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botones Funcionales
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.3,
                            children: [
                              _BotonAccion(icon: Icons.search, label: "Buscar", color: Colors.orange, onTap: _accionBuscar), // <--- CONECTADO
                              _BotonAccion(icon: Icons.delete_outline, label: "Borrar", color: Colors.redAccent, onTap: () {
                                setState(() { _carrito.clear(); _totalVenta=0; _clienteActual="Público General"; });
                              }),
                              _BotonAccion(icon: Icons.price_check, label: "Stock", color: Colors.purple, onTap: _accionStock), // <--- CONECTADO
                              _BotonAccion(icon: Icons.people_outline, label: "Cliente", color: Colors.teal, onTap: _accionCliente), // <--- CONECTADO
                              _BotonAccion(icon: Icons.logout, label: "Salir", color: Colors.grey.shade700, onTap: widget.onSalir),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _RenglonCarrito extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSumar;
  final VoidCallback onRestar;
  final VoidCallback onEditar;
  const _RenglonCarrito({required this.item, required this.onSumar, required this.onRestar, required this.onEditar});
  @override
  Widget build(BuildContext context) {
    final total = item['precio_venta'] * item['cantidad'];
    return InkWell(
      onDoubleTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['descripcion'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              if (item['precio_venta'] == 0) const Text("Sin Precio", style: TextStyle(color: Colors.red, fontSize: 10)),
            ])),
            Expanded(flex: 1, child: Text("\$${item['precio_venta']}", style: const TextStyle(fontSize: 13, color: Colors.grey))),
            Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _BotonCantidad(icon: Icons.remove, color: Colors.red.shade50, iconColor: Colors.red, onTap: onRestar),
              SizedBox(width: 30, child: Text("${item['cantidad']}", textAlign: TextAlign.center, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 15))),
              _BotonCantidad(icon: Icons.add, color: Colors.green.shade50, iconColor: Colors.green.shade800, onTap: onSumar),
            ])),
            Expanded(flex: 1, child: Text("\$${total.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _BotonCantidad({required this.icon, required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 16, color: iconColor)));
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BotonAccion({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(12), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha:  0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 8), Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))]))));
  }
}