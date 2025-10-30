import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LoginIllustration extends StatelessWidget {
  const LoginIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: Stack(
        children: [
          // Stars decoration
          Positioned(
            top: 60,
            right: 100,
            child: _buildStar(8),
          ),
          Positioned(
            top: 120,
            right: 200,
            child: _buildStar(6),
          ),
          Positioned(
            top: 200,
            left: 150,
            child: _buildStar(5),
          ),
          Positioned(
            bottom: 150,
            left: 100,
            child: _buildStar(7),
          ),
          Positioned(
            bottom: 250,
            right: 150,
            child: _buildStar(6),
          ),

          // Moon
          Positioned(
            top: 80,
            right: 120,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),

          // Main illustration - School building
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mountains background
                CustomPaint(
                  size: const Size(400, 150),
                  painter: MountainsPainter(),
                ),
                const SizedBox(height: 20),
                
                // School building
                SizedBox(
                  width: 300,
                  height: 250,
                  child: Stack(
                    children: [
                      // Main building
                      Positioned(
                        bottom: 0,
                        left: 50,
                        child: _buildBuilding(
                          width: 120,
                          height: 180,
                          color: AppColors.accent,
                        ),
                      ),
                      // Side building
                      Positioned(
                        bottom: 0,
                        right: 50,
                        child: _buildBuilding(
                          width: 100,
                          height: 140,
                          color: AppColors.accentLight,
                        ),
                      ),
                      // Trees
                      Positioned(
                        bottom: 0,
                        left: 20,
                        child: _buildTree(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 20,
                        child: _buildTree(),
                      ),
                    ],
                  ),
                ),
                
                // Ground
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.illustrationGround.withOpacity(0.6),
                        AppColors.illustrationGroundDark.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBuilding({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Windows
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.illustrationWindow,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Door
          Container(
            width: width * 0.4,
            height: height * 0.25,
            decoration: const BoxDecoration(
              color: AppColors.illustrationDoor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tree crown
        Container(
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.illustrationTree.withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
        ),
        // Tree trunk
        Container(
          width: 12,
          height: 20,
          color: AppColors.textDark.withOpacity(0.6),
        ),
      ],
    );
  }
}

class MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // First mountain
    paint.color = AppColors.primaryDark.withOpacity(0.6);
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height)
      ..close();
    canvas.drawPath(path1, paint);

    // Second mountain
    paint.color = AppColors.primaryDarker.withOpacity(0.7);
    final path2 = Path()
      ..moveTo(size.width * 0.4, size.height)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, paint);

    // Third mountain
    paint.color = AppColors.illustrationSky.withOpacity(0.5);
    final path3 = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
