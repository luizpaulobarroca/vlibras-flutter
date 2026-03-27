# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-27

### Added

- `VLibrasController` com ciclo de vida completo: `initialize()`, `translate()`, `dispose()`
- `VLibrasView` widget que renderiza o avatar VLibras em Flutter Web via `HtmlElementView`
- `VLibrasValue` e `VLibrasStatus` com 6 estados: `idle`, `initializing`, `ready`, `translating`, `playing`, `error`
- `VLibrasPlatform` interface abstrata para injeção de plataforma customizada e testes
- Suporte inicial exclusivo a Flutter Web (Android/iOS planejados para v2)
- App de exemplo com avatar flutuante snap-para-quinas e demonstração interativa
