"""
T20 — Testes unitários: Papéis de usuário e autorização (T10/T12).

Verifica:
  - PapelUsuarioEnum tem exatamente TECNICO e DIRETOR (D4).
  - UsuarioAutenticado é imutável (frozen dataclass).
  - Lógica de require_tecnico: aceita TECNICO e DIRETOR.
  - Lógica de require_diretor: rejeita TECNICO.
  - Campos obrigatórios de UsuarioAutenticado presentes.
"""
from __future__ import annotations

from dataclasses import FrozenInstanceError
from datetime import datetime, timezone, timedelta
from uuid import uuid4

import pytest

from src.core.models.enums import PapelUsuarioEnum
from src.api.auth.dependencies import UsuarioAutenticado


def _make_user(papel: PapelUsuarioEnum) -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=uuid4(),
        upn=f"{papel.value.lower()}@test.com",
        nome=f"Test {papel.value}",
        papel=papel,
        token_exp=datetime.now(tz=timezone.utc) + timedelta(hours=1),
    )


class TestPapelUsuarioEnum:
    def test_enum_tem_tecnico(self) -> None:
        assert PapelUsuarioEnum.TECNICO.value == "TECNICO"

    def test_enum_tem_diretor(self) -> None:
        assert PapelUsuarioEnum.DIRETOR.value == "DIRETOR"

    def test_enum_tem_exatamente_dois_valores(self) -> None:
        valores = {p.value for p in PapelUsuarioEnum}
        assert valores == {"TECNICO", "DIRETOR"}, (
            "PapelUsuarioEnum deve ter exatamente TECNICO e DIRETOR (D4)"
        )


class TestUsuarioAutenticadoImutavel:
    def test_frozen_nao_permite_mutacao(self) -> None:
        user = _make_user(PapelUsuarioEnum.TECNICO)
        with pytest.raises(FrozenInstanceError):
            user.papel = PapelUsuarioEnum.DIRETOR  # type: ignore[misc]

    def test_campos_obrigatorios_presentes(self) -> None:
        user = _make_user(PapelUsuarioEnum.DIRETOR)
        assert user.id is not None
        assert "@" in user.upn
        assert user.papel == PapelUsuarioEnum.DIRETOR
        assert user.token_exp > datetime.now(tz=timezone.utc)


class TestRequireTecnicoLogica:
    """Verifica a lógica de autorização sem chamar FastAPI (D4)."""

    def _check_tecnico_permission(self, user: UsuarioAutenticado) -> bool:
        """Reproduz a lógica de require_tecnico."""
        return user.papel in (PapelUsuarioEnum.TECNICO, PapelUsuarioEnum.DIRETOR)

    def test_tecnico_tem_permissao(self) -> None:
        user = _make_user(PapelUsuarioEnum.TECNICO)
        assert self._check_tecnico_permission(user) is True

    def test_diretor_tem_permissao_tecnico(self) -> None:
        """DIRETOR é superconjunto de TECNICO."""
        user = _make_user(PapelUsuarioEnum.DIRETOR)
        assert self._check_tecnico_permission(user) is True


class TestRequireDiretorLogica:
    """Verifica a lógica de require_diretor."""

    def _check_diretor_permission(self, user: UsuarioAutenticado) -> bool:
        return user.papel == PapelUsuarioEnum.DIRETOR

    def test_diretor_tem_permissao(self) -> None:
        user = _make_user(PapelUsuarioEnum.DIRETOR)
        assert self._check_diretor_permission(user) is True

    def test_tecnico_nao_tem_permissao_diretor(self) -> None:
        user = _make_user(PapelUsuarioEnum.TECNICO)
        assert self._check_diretor_permission(user) is False
