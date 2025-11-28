import 'package:flutter/material.dart';
import 'database_helper.dart';

class PantallaReportes extends StatefulWidget {
  const PantallaReportes({super.key});

  @override
  State<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends State<PantallaReportes> {
  List<Map<String, dynamic>> _ventasDelDia = [];
  double _totalDia = 0.0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final db = await DatabaseHelper().database;
    
    // 1. Obtener la fecha de HOY en formato texto (YYYY-MM-DD)
    String hoy = DateTime.now().toIso8601String().substring(0, 10);

    // 2. Consultar ventas que coincidan con esa fecha
    final res = await db.query(
      'ventas',
      where: 'fecha LIKE ?',
      whereArgs: ['$hoy%'],
      orderBy: 'id DESC', // Las más recientes arriba
    );

    // 3. Calcular total
    double suma = 0;
    for (var v in res) {
      suma += (v['total'] as num).toDouble();
    }

    setState(() {
      _ventasDelDia = res;
      _totalDia = suma;
      _cargando = false;
    });
  }

  // Función para ver qué se vendió en un ticket específico
  void _verDetalleTicket(Map<String, dynamic> venta) async {
    final db = await DatabaseHelper().database;
    final detalles = await db.rawQuery('''
      SELECT d.*, p.descripcion 
      FROM detalle_ventas d
      LEFT JOIN productos p ON d.producto_codigo = p.codigo
      WHERE d.venta_id = ?
    ''', [venta['id']]);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ticket #${venta['id']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(venta['fecha'].toString().substring(11, 16), style: const TextStyle(color: Colors.grey)), // Solo la hora
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final d = detalles[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d['descripcion']?.toString() ?? "Producto Eliminado"),
                      subtitle: Text("${d['cantidad']} x \$${d['precio_unitario']}"),
                      trailing: Text("\$${d['subtotal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL PAGADO", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("\$${venta['total']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Reporte del Día"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _cargarDatos, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. TARJETA DE RESUMEN TOTAL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: Column(
                    children: [
                      const Text("Ventas Totales Hoy", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(
                        "\$${_totalDia.toStringAsFixed(2)}", 
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 10),
                      Text("${_ventasDelDia.length} transacciones", style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text("Historial de Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),

                // 2. LISTA DE VENTAS
                Expanded(
                  child: _ventasDelDia.isEmpty 
                    ? const Center(child: Text("No hay ventas hoy... ¡A vender! 🚀"))
                    : ListView.builder(
                        itemCount: _ventasDelDia.length,
                        itemBuilder: (context, index) {
                          final venta = _ventasDelDia[index];
                          // Extraemos solo la hora (HH:MM) de la fecha larga
                          String hora = venta['fecha'].toString().substring(11, 16);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: const Icon(Icons.receipt, color: Colors.green),
                              ),
                              title: Text("Venta #${venta['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Hora: $hora  •  Pago: ${venta['metodo_pago']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "\$${venta['total']}", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.chevron_right, color: Colors.grey)
                                ],
                              ),
                              onTap: () => _verDetalleTicket(venta),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}