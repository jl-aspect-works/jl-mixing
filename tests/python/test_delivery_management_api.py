from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from jl_mixing.api.delivery_management import (
    DeliveryDeletePackageApiRequest,
    DeliveryStatusApiRequest,
    execute_delete_package,
    execute_status,
    parse_delete_package_args,
    parse_status_args,
)
from jl_mixing.delivery import DeliveryCreateRequest, create_delivery
from jl_mixing.errors import ArgumentError
from test_delivery_service import write_project


class DeliveryManagementApiTests(unittest.TestCase):
    def test_status_api_returns_machine_readable_delivery_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = write_project(Path(tmp))
            create_delivery(DeliveryCreateRequest(project, make_zip=True))

            payload, exit_code = execute_status(DeliveryStatusApiRequest(project))

            self.assertEqual(exit_code, 0)
            self.assertEqual(payload["api_version"], "1.0")
            self.assertEqual(payload["operation"], "delivery.status")
            self.assertEqual(payload["status"], "success")
            self.assertEqual(payload["data"]["state"], "ready")
            self.assertEqual(payload["data"]["package_state"], "current")

    def test_delete_package_api_returns_reconciled_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = write_project(Path(tmp))
            created = create_delivery(DeliveryCreateRequest(project, make_zip=True))

            payload, exit_code = execute_delete_package(
                DeliveryDeletePackageApiRequest(project, str(created.zip_name))
            )

            self.assertEqual(exit_code, 0)
            self.assertEqual(payload["operation"], "delivery.delete-package")
            self.assertEqual(payload["data"]["deleted_name"], created.zip_name)
            self.assertEqual(payload["data"]["delivery"]["package_state"], "none")

    def test_argument_contracts_are_explicit(self) -> None:
        project = Path("/tmp/project")
        self.assertEqual(
            parse_status_args(["--json", "--project", str(project)]),
            DeliveryStatusApiRequest(project),
        )
        self.assertEqual(
            parse_delete_package_args(
                ["--json", "--project", str(project), "--zip-name", "project-rev-01-20300101120000.zip"]
            ),
            DeliveryDeletePackageApiRequest(project, "project-rev-01-20300101120000.zip"),
        )
        with self.assertRaises(ArgumentError):
            parse_status_args(["--project", str(project)])
        with self.assertRaises(ArgumentError):
            parse_delete_package_args(["--json", "--project", str(project)])


if __name__ == "__main__":
    unittest.main()
