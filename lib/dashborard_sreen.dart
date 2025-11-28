import 'package:flutter/material.dart';
import 'package:talkbot_pos/inventario_screen.dart';
import 'package:talkbot_pos/pos_screen.dart';
import 'package:talkbot_pos/reportes_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget
{
  final Map<String, dynamic> usuario;
  const DashboardScreen({super.key, required this.usuario});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen>
{
  // Controla qué opción del menú está seleccionada
  int _selectedIndex = 0;
  bool _isMenuExtended = true; // Para colapsar o expandir el menú

  // Pantallas
  late List<Widget> _pantallas;
  @override
  void initState()
  {
    super.initState();
    _pantallas = [
      HomeScreen
      (
        onCambiarPestana: (int nuevoIndice)
        {
          setState(()
          {
            _selectedIndex = nuevoIndice;
          });
        },
      ),
      PantallaPosMinimalista
      (
        onSalir: ()
        {
          setState
          (()
          {
            _selectedIndex = 0;
          }
          );
        }
      ), // Índice 1: POS

      const PantallaReportes(), // Índice 2: Reportes
      const PantallaInventario(), // Índice 3
    ];
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: Row
      (
        children:
        [
          NavigationRail
          (
            extended: _isMenuExtended, // ¿Menú ancho o solo iconos?
            backgroundColor: Colors.grey.shade200,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index)
            {
              setState(()
              {
                _selectedIndex = index;
              });
            },
            // Botón para cerrar sesión o colapsar menú
            leading: IconButton
            (
              icon: Icon(_isMenuExtended ? Icons.arrow_back_ios : Icons.arrow_forward_ios),
              onPressed: ()
              {
                setState(()
                {
                  _isMenuExtended = !_isMenuExtended;
                });
              },
            ),
            // LOS BOTONES DEL MENÚ
            destinations: const
            [
              NavigationRailDestination
              (
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination
              (
                icon: Icon(Icons.point_of_sale),
                label: Text('POS'),
              ),
              NavigationRailDestination
              (
                icon: Icon(Icons.bar_chart), // Icono de gráfica para Reportes
                label: Text('Reportes'),
              ),
              NavigationRailDestination
              (
                icon: Icon(Icons.inventory),
                label: Text('Inventarios'),
              ),
            ],
          ),

          // LÍNEA DIVISORIA VERTICAL
          const VerticalDivider(thickness: 1, width: 1),

          // 2. CONTENIDO PRINCIPAL (CAMBIA DINÁMICAMENTE)
          Expanded
          (
            child: _pantallas[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// --- PLACEHOLDER PARA LA PANTALLA DE REPORTES ---
class PantallaReportesPlaceholder extends StatelessWidget
{
  const PantallaReportesPlaceholder({super.key});
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar(title: const Text("Reportes y Proveedores"), backgroundColor: Colors.grey),
      body: SingleChildScrollView
      ( // Para que quepa todo si la pantalla es chica
      padding: const EdgeInsets.all(16.0),
      child: Column
      (
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
        [
          // FILTROS SUPERIORES
          Row
          (
            children:
            [
              const Text("Filtro: "),
              Expanded(child: TextField(decoration: InputDecoration(hintText: "Proveedor...", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () {}, child: const Text("Buscar"))
            ],
          ),
          const SizedBox(height: 20),
            // MOCKUP DE LAS TABLAS
            Row
            (
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
              [
                // TABLA IZQUIERDA: VENTAS
                Expanded
                (
                  flex: 2,
                  child: Card
                  (
                    elevation: 4,
                    child: Column
                    (
                      children:
                      [
                        Container(width: double.infinity, color: Colors.grey.shade300, padding: EdgeInsets.all(8), child: Text("Ventas Relacionadas")),
                        const SizedBox(height: 100, child: Center(child: Text("Tabla de ventas aquí..."))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // TABLA DERECHA: ENVASE A ENTREGAR (RETORNABLES)
                Expanded
                (
                  flex: 1,
                  child: Card
                  (
                    color: Colors.orange.shade50, // Color para resaltar atención
                    elevation: 4,
                    child: Column
                    (
                      children:
                      [
                        Container(width: double.infinity, color: Colors.orange.shade200, padding: EdgeInsets.all(8), child: Text("⚠ Envase a Entregar")),
                        Padding
                        (
                          padding: const EdgeInsets.all(8.0),
                          child: Column
                          (
                            children: const
                            [
                              ListTile(title: Text("Cartón Carta Blanca"), trailing: Text("3 Cajas")),
                              ListTile(title: Text("Envase Coca 2.5L"), trailing: Text("12 Pzas")),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),            
            const SizedBox(height: 20),

            // SECCIÓN INFERIOR: PEDIDOS Y PAGOS
            Row
            (
              children:
              [
                Expanded
                (
                  child: Card
                  (
                    child: Column
                    (
                      children:
                      [
                        Container(width: double.infinity, color: Colors.blue.shade100, padding: EdgeInsets.all(8), child: Text("Pedido a Recibir")),
                        const SizedBox(height: 50, child: Center(child: Text("Lista de pedido..."))),
                      ],
                    ),
                  ),
                ),
                 Expanded
                 (
                  child: Card
                  (
                    child: Column
                    (
                      children:
                      [
                        Container(width: double.infinity, color: Colors.green.shade100, padding: EdgeInsets.all(8), child: Text("Monto a Pagar")),
                        const Padding
                        (
                          padding: EdgeInsets.all(20.0),
                          child: Text("\$ 12,450.00", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}