import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

void main() {
  runApp(GameWidget(game: BrotatoGame()));
}

class BrotatoGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late JoystickComponent joystick;
  double enemyTimer = 0;

  @override
  Future<void> onLoad() async {
    // Fundo da arena
    add(RectangleComponent(
      size: Vector2(2000, 2000),
      position: Vector2(-500, -500),
      paint: Paint()..color = const Color(0xFF222222),
    ));

    // Jogador (Quadrado Azul)
    player = Player();
    add(player);

    // Joystick virtual para celular
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final backgroundPaint = Paint()..color = Colors.white.withOpacity(0.2);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 60, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);

    camera.follow(player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Movimentar jogador via Joystick
    if (!joystick.delta.isZero()) {
      player.position.add(joystick.relativeDelta * player.speed * dt);
    }

    // Gerar inimigos a cada 1.5 segundos
    enemyTimer += dt;
    if (enemyTimer > 1.5) {
      enemyTimer = 0;
      spawnEnemy();
    }
  }

  void spawnEnemy() {
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final spawnDistance = 400.0;
    final spawnPos = player.position + Vector2(cos(angle), sin(angle)) * spawnDistance;
    add(Enemy(spawnPos));
  }
}

// JOGADOR
class Player extends PositionComponent with HasGameRef<BrotatoGame> {
  final double speed = 180.0;
  double shootTimer = 0;

  Player() : super(size: Vector2(32, 32), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.cyanAccent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Tiro automático no inimigo mais próximo
    shootTimer += dt;
    if (shootTimer >= 0.5) {
      shootTimer = 0;
      shootNearestEnemy();
    }
  }

  void shootNearestEnemy() {
    Enemy? nearest;
    double minDistance = 350.0;

    for (final child in gameRef.children) {
      if (child is Enemy) {
        final dist = position.distanceTo(child.position);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = child;
        }
      }
    }

    if (nearest != null) {
      final direction = (nearest.position - position).normalized();
      gameRef.add(Bullet(position.clone(), direction));
    }
  }
}

// INIMIGO (Quadrado Vermelho que persegue o jogador)
class Enemy extends PositionComponent with HasGameRef<BrotatoGame> {
  final double speed = 90.0;

  Enemy(Vector2 startPos) : super(position: startPos, size: Vector2(28, 28), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.redAccent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = gameRef.player.position;
    final dir = (target - position).normalized();
    position.add(dir * speed * dt);
  }
}

// BALA / PROJÉTIL
class Bullet extends PositionComponent with HasGameRef<BrotatoGame> {
  final Vector2 direction;
  final double speed = 400.0;
  double lifeTime = 0;

  Bullet(Vector2 startPos, this.direction) : super(position: startPos, size: Vector2(8, 8), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, Paint()..color = Colors.yellowAccent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(direction * speed * dt);

    // Verifica colisão simples com inimigos
    for (final child in gameRef.children) {
      if (child is Enemy && position.distanceTo(child.position) < 20) {
        child.removeFromParent(); // Mata o inimigo
        removeFromParent();      // Destrói a bala
        return;
      }
    }

    lifeTime += dt;
    if (lifeTime > 2.0) removeFromParent();
  }
}
