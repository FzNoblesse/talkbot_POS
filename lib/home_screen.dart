import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onCambiarPestana;

  const HomeScreen({super.key, required this.onCambiarPestana});

  @override
  Widget build(BuildContext context) {
    // DEFINIMOS EL MENÚ
    final List<Map<String, dynamic>> menuItems = [
      {
        "titulo": "Iniciar Venta",
        "icon": Icons.point_of_sale,
        "color": Colors.green,
        "ruta": 1,
      },
      {
        "titulo": "Corte de caja",
        "icon": Icons.request_quote,
        "color": Colors.blue,
      },
      {
        "titulo": "Productos más Vendidos",
        "icon": Icons.trending_up,
        "color": Colors.orange,
      },
      {
        "titulo": "Registro de Gastos",
        "icon": Icons.money_off,
        "color": Colors.redAccent,
      },
      {
        "titulo": "Inventario rápido",
        "icon": Icons.inventory_2,
        "color": Colors.purple,
      },
      {
        "titulo": "Clientes (Fiado)",
        "icon": Icons.people_alt,
        "color": Colors.teal,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Menú Principal",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const Divider(),
            const SizedBox(height: 20),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  
                  // Creamos la tarjeta y le decimos QUÉ HACER al dar click
                  return _MenuCard(
                    item: item,
                    // Esta es la acción que se ejecuta al tocar la tarjeta:
                    onTap: () {
                      if (item.containsKey('ruta')) {
                        // Si tiene ruta, usamos el control remoto para cambiar pestaña
                        onCambiarPestana(item['ruta']);
                      } else {
                        // Si no, solo mostramos un mensaje
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Opción: ${item['titulo']}")),
                        );
                      }
                    },
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

// Ahora recibe el 'onTap' desde arriba para saber qué hacer
class _MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _MenuCard({
    super.key, 
    required this.item, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap, // <--- Aquí conectamos el click con la acción que nos mandaron
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                // Corrección del color que me pediste antes:
                color: (item['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'],
                size: 50,
                color: item['color'],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item['titulo'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}