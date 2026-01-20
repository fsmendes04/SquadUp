import 'package:flutter/material.dart';

/// Utilitário para dimensões responsivas baseado em um dispositivo de referência
/// Referência: 412 x 915 dp (dimensões perfeitas do design)
class ResponsiveUtils {
  // Dimensões de referência
  static const double _refWidth = 412.0;
  static const double _refHeight = 915.0;

  final BuildContext context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _widthScale;
  late final double _heightScale;

  ResponsiveUtils(this.context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _widthScale = _screenWidth / _refWidth;
    _heightScale = _screenHeight / _refHeight;
  }

  /// Retorna largura escalada proporcionalmente
  double width(double referenceWidth) => referenceWidth * _widthScale;

  /// Retorna altura escalada proporcionalmente
  double height(double referenceHeight) => referenceHeight * _heightScale;

  /// Retorna tamanho de fonte escalado proporcionalmente (baseado na largura)
  double fontSize(double referenceFontSize) => referenceFontSize * _widthScale;

  /// Retorna padding horizontal escalado
  EdgeInsets horizontalPadding(double referencePadding) =>
      EdgeInsets.symmetric(horizontal: referencePadding * _widthScale);

  /// Retorna padding vertical escalado
  EdgeInsets verticalPadding(double referencePadding) =>
      EdgeInsets.symmetric(vertical: referencePadding * _heightScale);

  /// Retorna padding simétrico escalado
  EdgeInsets symmetricPadding({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(
        horizontal: horizontal * _widthScale,
        vertical: vertical * _heightScale,
      );

  /// Retorna padding completo escalado
  EdgeInsets padding({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: left * _widthScale,
        top: top * _heightScale,
        right: right * _widthScale,
        bottom: bottom * _heightScale,
      );

  /// Retorna SizedBox com altura escalada
  Widget verticalSpace(double referenceHeight) =>
      SizedBox(height: height(referenceHeight));

  /// Retorna SizedBox com largura escalada
  Widget horizontalSpace(double referenceWidth) =>
      SizedBox(width: width(referenceWidth));

  /// Retorna border radius escalado
  double borderRadius(double referenceBorderRadius) =>
      referenceBorderRadius * _widthScale;

  /// Retorna BorderRadius circular escalado
  BorderRadius circularBorderRadius(double referenceBorderRadius) =>
      BorderRadius.circular(borderRadius(referenceBorderRadius));

  /// Retorna border width escalada
  double borderWidth(double referenceBorderWidth) =>
      referenceBorderWidth * _widthScale;

  /// Retorna icon size escalado
  double iconSize(double referenceIconSize) => referenceIconSize * _widthScale;

  // Getters de acesso rápido para valores comuns
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get widthScale => _widthScale;
  double get heightScale => _heightScale;

  // Valores comuns pré-definidos
  double get spacing4 => height(4);
  double get spacing8 => height(8);
  double get spacing10 => height(10);
  double get spacing16 => height(16);
  double get spacing20 => height(20);
  double get spacing30 => height(30);
  double get spacing40 => height(40);
  double get spacing50 => height(50);

  // Paddings comuns
  EdgeInsets get defaultHorizontalPadding => horizontalPadding(30);
  EdgeInsets get defaultCardPadding => symmetricPadding(horizontal: 16, vertical: 12);
  
  // Tamanhos de fonte comuns
  double get fontSizeSmall => fontSize(12);
  double get fontSizeRegular => fontSize(14);
  double get fontSizeMedium => fontSize(16);
  double get fontSizeLarge => fontSize(18);
  double get fontSizeTitle => fontSize(24);
  double get fontSizeHeading => fontSize(30);
}

/// Extension para facilitar o acesso ao ResponsiveUtils
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}
