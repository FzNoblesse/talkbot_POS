import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para filtrar solo números
import 'database_helper.dart';
import 'login_screen.dart';

void main()
{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiTienditaApp());
}

class MiTienditaApp extends StatelessWidget
{
  const MiTienditaApp({super.key});
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp
    (
      debugShowCheckedModeBanner: false,
      title: 'POS Tiendita',
      theme: ThemeData
      (
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class PantallaVenta extends StatefulWidget {
  const PantallaVenta({super.key});

  @override
  State<PantallaVenta> createState() => _PantallaVentaState();
}

class _PantallaVentaState extends State<PantallaVenta> {
  // --- VARIABLES ---
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  final List<Map<String, dynamic>> _carrito = []; 
  double _totalVenta = 0.0;
  final TextEditingController _searchController = TextEditingController();

  // --- LÓGICA ---

  void _buscar(String texto) async {
    if (texto.isEmpty) {
      setState(() => _resultadosBusqueda = []);
      return;
    }
    final datos = await DatabaseHelper().buscarPorNombre(texto);
    setState(() {
      _resultadosBusqueda = datos;
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      int indiceExistente = _carrito.indexWhere((item) => item['codigo'] == producto['codigo']);

      if (indiceExistente != -1) {
        _carrito[indiceExistente]['cantidad']++;
      } else {
        Map<String, dynamic> itemVenta = Map.from(producto);
        itemVenta['precio_venta'] = 15.00; // Precio simulado
        itemVenta['cantidad'] = 1;
        _carrito.add(itemVenta);
      }
      _calcularTotal();
    });
    
    _searchController.clear(); 
    _resultadosBusqueda = [];
  }

  // Esta función ahora recibe el valor directo de la cajita de texto
  void _actualizarCantidadExacta(int index, String valor) {
    int? nuevaCantidad = int.tryParse(valor);
    if (nuevaCantidad != null && nuevaCantidad > 0) {
      setState(() {
        _carrito[index]['cantidad'] = nuevaCantidad;
        _calcularTotal();
      });
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    double tempTotal = 0;
    for (var item in _carrito) {
      double precio = item['precio_venta'] ?? 0.0;
      int cantidad = item['cantidad'] ?? 1;
      tempTotal += (precio * cantidad);
    }
    setState(() {
      _totalVenta = tempTotal;
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Punto de Venta"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Row(
        children: [
          // IZQUIERDA: BUSCADOR
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '🔍 Buscar producto',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: _buscar,
                    autofocus: true,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _resultadosBusqueda.length,
                      itemBuilder: (context, index) {
                        final prod = _resultadosBusqueda[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.qr_code),
                            title: Text(prod['descripcion'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _agregarAlCarrito(prod),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // DERECHA: TICKET CON CAJITA DE CANTIDAD
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Resumen de compra", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  
                  // LISTA DE PRODUCTOS
                  Expanded(
                    child: _carrito.isEmpty
                        ? const Center(child: Text("Carrito vacío"))
                        : ListView.builder(
                            itemCount: _carrito.length,
                            itemBuilder: (context, index) {
                              final item = _carrito[index];
                              
                              // Usamos un Widget separado para evitar errores de foco al escribir
                              return RenglonProducto(
                                key: ValueKey(item['codigo']), // Importante para no perder el estado
                                item: item,
                                alCambiarCantidad: (val) => _actualizarCantidadExacta(index, val),
                                alBorrar: () => _eliminarDelCarrito(index),
                              );
                            },
                          ),
                  ),
                  
                  const Divider(),
                  // TOTAL Y BOTÓN COBRAR
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text("\$${_totalVenta.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: _carrito.isEmpty ? null : () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Venta Cobrada! 💰")));
                              setState(() {
                                _carrito.clear();
                                _totalVenta = 0;
                              });
                            },
                            child: const Text("COBRAR (F12)", style: TextStyle(fontSize: 18)),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PERSONALIZADO PARA EL RENGLÓN DEL TICKET ---
// Separamos esto para que la cajita de texto funcione suave
class RenglonProducto extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(String) alCambiarCantidad;
  final VoidCallback alBorrar;

  const RenglonProducto({
    super.key, 
    required this.item, 
    required this.alCambiarCantidad, 
    required this.alBorrar
  });

  @override
  State<RenglonProducto> createState() => _RenglonProductoState();
}

class _RenglonProductoState extends State<RenglonProducto> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    // Inicializamos la cajita con la cantidad actual (ej. "1")
    _qtyController = TextEditingController(text: widget.item['cantidad'].toString());
  }

  @override
  void didUpdateWidget(RenglonProducto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la cantidad cambia desde fuera (ej. escaneas otro producto igual), actualizamos la cajita
    if (oldWidget.item['cantidad'] != widget.item['cantidad']) {
      // Solo actualizamos si el usuario NO está escribiendo actualmente para no interrumpirlo
      if (!_qtyController.selection.isValid) { 
         _qtyController.text = widget.item['cantidad'].toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double precio = widget.item['precio_venta'] ?? 0.0;
    int cantidad = widget.item['cantidad'] ?? 1;
    double subtotal = precio * cantidad;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          children: [
            // 1. NOMBRE DEL PRODUCTO (Se expande para llenar espacio)
            Expanded(
              child: Text(
                widget.item['descripcion'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 2. PRECIO TOTAL DEL RENGLÓN
            Text(
              "\$${subtotal.toStringAsFixed(2)}", 
              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(width: 10),

            // 3. CAJITA DE CANTIDAD (EL RECUADRO)
            Container(
              width: 50,
              height: 35,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                // Esto permite que solo entren números
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12), // Ajuste visual para centrar el número
                ),
                onChanged: (val) => widget.alCambiarCantidad(val),
              ),
            ),

            const SizedBox(width: 5),

            // 4. BOTÓN DE BORRAR
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: widget.alBorrar,
              tooltip: "Quitar",
            ),
          ],
        ),
      ),
    );
  }
}