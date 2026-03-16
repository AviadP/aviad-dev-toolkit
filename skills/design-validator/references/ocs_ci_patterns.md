# OCS-CI Patterns and Anti-Patterns

This reference provides detailed examples of correct and incorrect patterns in the OCS-CI codebase.

## Fixture Usage Patterns

### ✅ CORRECT: Using Factories

```python
class TestPVC(ManageTest):
    def test_create_pvc(self, pvc_factory, pod_factory):
        """Test PVC creation and usage"""
        # Factory handles cleanup automatically
        pvc = pvc_factory(
            interface=constants.CEPHBLOCKPOOL,
            size=10
        )
        pod = pod_factory(pvc=pvc)
        assert pod.status == "Running"
```

**Why:** Factories provide automatic cleanup via finalizers. Resources are cleaned up even if test fails.

### ❌ INCORRECT: Manual Resource Creation

```python
class TestPVC(ManageTest):
    def test_create_pvc(self):
        """Test PVC creation and usage"""
        # Manual cleanup is error-prone
        pvc = create_pvc(size=10)
        try:
            pod = create_pod(pvc=pvc)
            assert pod.status == "Running"
        finally:
            pod.delete()
            pvc.delete()
```

**Why:** Manual cleanup in try/finally is error-prone. If cleanup fails, resources leak. Factories handle this better.

## Fixture Anti-Patterns

### ❌ INCORRECT: Using request.node.cls

```python
@pytest.fixture
def setup_test(request):
    # Anti-pattern: Using request.node.cls
    request.node.cls.test_data = {"key": "value"}
    yield
    del request.node.cls.test_data
```

**Why:** This creates hidden coupling between fixtures and test classes. Data sharing should be explicit.

### ❌ INCORRECT: Using Globals

```python
# Anti-pattern: Global state
TEST_PVC = None

@pytest.fixture
def pvc():
    global TEST_PVC
    TEST_PVC = create_pvc()
    yield TEST_PVC
    TEST_PVC.delete()
```

**Why:** Globals make tests interdependent and hard to parallelize.

### ❌ INCORRECT: Using @pytest.mark.usefixtures

```python
@pytest.mark.usefixtures("setup_bucket")  # Anti-pattern
class TestBucket(ManageTest):
    def test_bucket(self):
        # Unclear where setup_bucket is used
        pass
```

**Why:** Makes fixture dependencies implicit. Prefer explicit fixture arguments.

### ❌ INCORRECT: Using yield in Fixtures

```python
@pytest.fixture
def my_resource():
    resource = create_resource()
    yield resource  # Anti-pattern in OCS-CI
    resource.cleanup()
```

**Why:** OCS-CI convention is to avoid yield. Use finalizers with request.addfinalizer instead.

### ✅ CORRECT: Using Finalizers

```python
@pytest.fixture
def my_resource(request):
    resource = create_resource()
    request.addfinalizer(resource.cleanup)
    return resource
```

**Why:** Explicit cleanup order and better error handling.

### ❌ INCORRECT: Multiple Asserts in Teardown

```python
def test_example(self, resource_factory):
    resource = resource_factory()
    # Test code...

    # Anti-pattern: Multiple asserts with actions between
    assert resource.exists()
    resource.delete()
    assert not resource.exists()
    another_resource.delete()  # This won't run if second assert fails
```

**Why:** If the second assert fails, the subsequent cleanup won't run, leaking resources.

## Exception Handling Patterns

### ✅ CORRECT: Specific Exceptions

```python
def get_config_file(path: str) -> dict:
    """Read configuration file"""
    if not os.path.exists(path):
        return {}

    try:
        with open(path) as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        logger.error(f"Config file not found: {path}")
        return {}
    except yaml.YAMLError as e:
        logger.error(f"Invalid YAML in {path}: {e}")
        raise
```

**Why:** Specific exceptions make error handling precise. Early returns avoid nesting.

### ❌ INCORRECT: General Exception

```python
def get_config_file(path: str) -> dict:
    """Read configuration file"""
    try:
        with open(path) as f:
            return yaml.safe_load(f)
    except Exception as e:  # Anti-pattern: Too broad
        logger.error(f"Error: {e}")
        return {}
```

**Why:** Catches unexpected errors (like KeyboardInterrupt). Makes debugging harder.

## Function Design Patterns

### ✅ CORRECT: Early Returns

```python
def create_bucket(name: str, versioning: bool = False) -> dict:
    """
    Create S3 bucket

    Args:
        name (str): Bucket name
        versioning (bool): Enable versioning

    Returns:
        dict: Bucket configuration

    Raises:
        ValueError: If name is invalid
    """
    # Error handling first
    if not name:
        raise ValueError("Bucket name cannot be empty")

    if not is_valid_bucket_name(name):
        raise ValueError(f"Invalid bucket name: {name}")

    # Happy path last
    config = {"name": name}
    bucket = s3_client.create_bucket(config)

    if versioning:
        enable_bucket_versioning(bucket)

    return bucket
```

**Why:** Errors handled early, happy path clear, single responsibility, type hints present.

### ❌ INCORRECT: Nested If/Else

```python
def create_bucket(name, versioning=False):  # Missing type hints
    if name:
        if is_valid_bucket_name(name):
            config = {"name": name}
            bucket = s3_client.create_bucket(config)
            if versioning:
                enable_bucket_versioning(bucket)
                return bucket
            else:
                return bucket
        else:
            raise ValueError(f"Invalid bucket name: {name}")
    else:
        raise ValueError("Bucket name cannot be empty")
```

**Why:** Deep nesting, unclear flow, no type hints, unnecessary else statements.

## Test Class Patterns

### ✅ CORRECT: Proper Inheritance

```python
@pytest.mark.tier1
@pytest.mark.green_squad
@pytest.mark.polarion_id("OCS-1234")
class TestBucketVersioning(ManageTest):
    """Test bucket versioning functionality"""

    def test_enable_versioning(self, bucket_factory):
        """Test enabling bucket versioning"""
        bucket = bucket_factory()
        enable_bucket_versioning(bucket)
        assert is_bucket_versioned(bucket)
```

**Why:** Proper base class, complete markers, clear purpose, uses factories.

### ❌ INCORRECT: Missing Conventions

```python
class TestBucketVersioning:  # Missing base class
    def test_enable_versioning(self):  # No fixtures
        bucket = create_bucket("test-bucket")  # Manual creation
        enable_bucket_versioning(bucket)
        assert is_bucket_versioned(bucket)
        # No cleanup
```

**Why:** No base class, no markers, manual resource creation, no cleanup.

## Code Reusability Patterns

### ✅ CORRECT: Check for Existing Functions

Before creating a new helper function, search for existing implementations:

```bash
# Search for similar functionality
grep -r "enable.*version" ocs_ci/helpers/
grep -r "bucket.*version" ocs_ci/ocs/
```

If found, use or extend existing function rather than duplicating.

### ✅ CORRECT: Shared Helpers

```python
# In ocs_ci/helpers/bucket_helper.py
def enable_bucket_versioning(bucket_name: str) -> None:
    """
    Enable versioning on S3 bucket

    Args:
        bucket_name (str): Name of bucket
    """
    s3_client.put_bucket_versioning(
        Bucket=bucket_name,
        VersioningConfiguration={'Status': 'Enabled'}
    )
```

```python
# In test file - reuse helper
from ocs_ci.helpers.bucket_helper import enable_bucket_versioning

class TestBucketVersioning(ManageTest):
    def test_enable_versioning(self, bucket_factory):
        bucket = bucket_factory()
        enable_bucket_versioning(bucket.name)  # Reuse shared helper
```

**Why:** Shared helpers in `ocs_ci/helpers/` are reusable across tests. Avoids duplication.

### ❌ INCORRECT: Duplicating Logic

```python
class TestBucketVersioning(ManageTest):
    def enable_versioning(self, bucket_name):  # Duplicating existing helper
        """Enable versioning - duplicates existing helper"""
        s3_client.put_bucket_versioning(
            Bucket=bucket_name,
            VersioningConfiguration={'Status': 'Enabled'}
        )

    def test_enable_versioning(self, bucket_factory):
        bucket = bucket_factory()
        self.enable_versioning(bucket.name)
```

**Why:** Creates duplicate code. Should use existing helper from `ocs_ci/helpers/`.

## UI Test Patterns

### ✅ CORRECT: Minimal Interactions

```python
def test_enable_bucket_versioning_ui(self, bucket_factory):
    """Test enabling versioning via UI"""
    bucket = bucket_factory()

    # Navigate directly to bucket details
    buckets_page = BucketsPage()
    bucket_details = buckets_page.navigate_to_bucket_details(bucket.name)

    # Enable versioning
    bucket_details.click_enable_versioning()

    # Verify
    assert bucket_details.is_versioning_enabled()
```

**Why:** Direct navigation, minimal clicks, clear purpose.

### ❌ INCORRECT: Excessive Interactions

```python
def test_enable_bucket_versioning_ui(self, bucket_factory):
    """Test enabling versioning via UI"""
    bucket = bucket_factory()

    # Anti-pattern: Unnecessary navigation through menus
    nav_menu = NavigationMenu()
    nav_menu.click_storage()
    nav_menu.click_object_storage()
    nav_menu.click_buckets()

    buckets_page = BucketsPage()
    buckets_page.search_bucket(bucket.name)
    buckets_page.click_search_result(0)

    # More unnecessary steps...
```

**Why:** Excessive interactions create timing issues and state dependencies. Navigate directly when possible.

### ❌ INCORRECT: Timing-Based Fixes

```python
def test_bucket_details(self):
    buckets_page.navigate_to_bucket_details("my-bucket")
    time.sleep(5)  # Anti-pattern: Waiting for page load
    assert buckets_page.get_bucket_name() == "my-bucket"
```

**Why:** Timing fixes mask architectural issues. Use proper wait conditions or fix the navigation logic.

### ✅ CORRECT: Architectural Fix

```python
def navigate_to_bucket_details(self, bucket_name: str):
    """Navigate to bucket details page"""
    # Wait for page to be ready
    self.wait_for_element(self.BUCKETS_TABLE)
    # Then navigate
    self.click_bucket_row(bucket_name)
    # Verify navigation succeeded
    self.wait_for_element(self.BUCKET_DETAILS_HEADER)
```

**Why:** Proper wait conditions ensure page is ready. No arbitrary sleeps.

## Performance Patterns

### ✅ CORRECT: Batch Operations

```python
def create_multiple_pvcs(count: int, pvc_factory) -> list:
    """Create multiple PVCs efficiently"""
    # Create all at once, don't wait for each
    pvcs = []
    for i in range(count):
        pvc = pvc_factory(wait=False)  # Don't wait yet
        pvcs.append(pvc)

    # Wait for all together
    for pvc in pvcs:
        pvc.ocp.wait_for_resource(...)

    return pvcs
```

**Why:** Parallel creation is faster than serial. Batch waiting is more efficient.

### ❌ INCORRECT: Serial Operations

```python
def create_multiple_pvcs(count: int, pvc_factory) -> list:
    """Create multiple PVCs inefficiently"""
    pvcs = []
    for i in range(count):
        pvc = pvc_factory()  # Waits for each one
        pvcs.append(pvc)
    return pvcs
```

**Why:** Waits for each PVC individually. Slow and inefficient.

## Logging Patterns

### ✅ CORRECT: Strategic Logging

```python
def enable_bucket_versioning(bucket_name: str) -> None:
    """Enable bucket versioning"""
    logger.info(f"Enabling versioning for bucket: {bucket_name}")

    try:
        response = s3_client.put_bucket_versioning(...)
        logger.debug(f"Versioning enabled successfully: {response}")
    except ClientError as e:
        logger.error(f"Failed to enable versioning for {bucket_name}: {e}")
        raise
```

**Why:** Info log at start, debug for details, error for failures. Not excessive.

### ❌ INCORRECT: Excessive Logging

```python
def enable_bucket_versioning(bucket_name: str) -> None:
    """Enable bucket versioning"""
    logger.info(f"Starting versioning enable")
    logger.info(f"Bucket name: {bucket_name}")
    logger.info(f"Creating config")
    config = {'Status': 'Enabled'}
    logger.info(f"Config created: {config}")
    logger.info(f"Calling put_bucket_versioning")
    response = s3_client.put_bucket_versioning(...)
    logger.info(f"Response received")
    logger.info(f"Response: {response}")
    logger.info(f"Versioning enabled")
```

**Why:** Too many logs create noise. Hard to find important information.

## Common Reusability Checks

When validating a plan, check these locations for existing functionality:

1. **Factories**: `conftest.py` files for resource factories
2. **Helpers**: `ocs_ci/helpers/` for helper functions
3. **OCS modules**: `ocs_ci/ocs/` for OCS-specific functionality
4. **Utilities**: `ocs_ci/utility/` for general utilities
5. **UI helpers**: `ocs_ci/ocs/ui/` for UI-related helpers

**Search commands:**
```bash
# Find similar functionality
grep -r "function_name_pattern" ocs_ci/
grep -r "class.*NamePattern" ocs_ci/
```
